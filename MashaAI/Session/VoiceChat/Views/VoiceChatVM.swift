import Foundation
import Combine
import ElevenLabsSDK

final class VoiceChatVM: ObservableObject {

    enum ViewState {
        case loading
        case connected
        case error
    }

    @Published
    private(set) var status: ElevenLabsSDK.Status = .disconnected

    @Published
    var isConnecting = false

    @Published
    var lastError: String?

    @Published
    private(set) var mode: ElevenLabsSDK.Mode = .listening

    @Published
    private(set) var connectionRetryCount = 0

    @Published
    private(set) var audioLevel: Float = 0.0

    @Published
    private(set) var viewState: ViewState = .loading

    private let config = ElevenLabsSDK.SessionConfig(agentId: "w63wjugjg9aztG1H9JDa")
    private var currentAgentIndex = 0
    private var conversation: ElevenLabsSDK.Conversation?
    private var connectionTask: Task<Void, Never>?
    
    private func startConnection(agent: Agent) async {
        do {
            print("🚀 Starting conversation session (attempt \(connectionRetryCount + 10))...")

            // Увеличиваем задержку для стабильности
            try await Task.sleep(nanoseconds: 1_000_000_000)  // 1 секунда

            // Проверяем, не была ли отменена задача
            try Task.checkCancellation()

            // Упрощенная конфигурация без переопределений
            let config = ElevenLabsSDK.SessionConfig(agentId: agent.id)

            var callbacks = ElevenLabsSDK.Callbacks()

            callbacks.onConnect = { [weak self] conversationId in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.viewState = .connected
                    print("✅ Connected successfully with ID: \(conversationId)")
                    self.status = .connected
                    self.isConnecting = false
                    self.connectionRetryCount = 0
                    self.lastError = nil
                }
            }

            callbacks.onDisconnect = { [weak self] in
                DispatchQueue.main.async {
                    guard let self else { return }

                    print("🔌 Disconnected")
                    if self.status == .connected {
                        // Неожиданное отключение
                        self.lastError = "Connection lost unexpectedly"
                    }
                    self.stopConversation()
                }
            }

            callbacks.onMessage = { message, role in
                DispatchQueue.main.async {
                    print("💬 Message (\(role)): \(message)")
                }
            }

            callbacks.onError = { [weak self] errorMessage, errorCode in
                DispatchQueue.main.async {
                    guard let self else { return }
                    print("❌ Error (\(errorCode ?? -1)): \(errorMessage)")

                    self.viewState = .error

                    // Игнорируем ошибки, связанные с коррекцией ответов агента (при перебивании)
                    if self.isAgentCorrectionError(errorMessage) {
                        print("ℹ️ Agent response correction detected - this is normal when interrupting")
                        return
                    }

                    self.lastError = errorMessage

                    // Проверяем, стоит ли повторить попытку
                    if self.shouldRetryConnection(errorMessage: errorMessage) && self.connectionRetryCount < 2 {
                        self.connectionRetryCount += 1
                        print("🔄 Will retry connection (\(self.connectionRetryCount)/2) in 3 seconds...")

                        // Увеличиваем интервал между попытками
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            if !self.isConnecting && self.status != .connected {
                                self.connectionTask = Task {
                                    await self.startConnection(agent: agent)
                                }
                            }
                        }
                    } else {
                        print("💥 Max retries reached or non-retryable error")
                        self.stopConversation()
                    }
                }
            }

            callbacks.onStatusChange = { [weak self] newStatus in
                DispatchQueue.main.async {
                    guard let self else { return }

                    print("📊 Status changed: \(newStatus)")
                    self.status = newStatus

                    if newStatus == .disconnected {
                        self.isConnecting = false
                    }
                }
            }

            callbacks.onModeChange = { [weak self] newMode in
                DispatchQueue.main.async {
                    guard let self else { return }
                    print("🎤 Mode changed: \(newMode)")
                    self.mode = newMode
                }
            }

            callbacks.onVolumeUpdate = { [weak self] newVolume in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.audioLevel = max(0, min(1, newVolume))
                }
            }

            // Пытаемся установить соединение
            conversation = try await ElevenLabsSDK.Conversation.startSession(
                config: config,
                callbacks: callbacks
            )

        } catch {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                print("💥 Failed to start conversation: \(error.localizedDescription)")
                self.lastError = error.localizedDescription
                self.stopConversation()
            }
        }
    }

    func stopConversation() {
        print("🧹 Cleaning up conversation...")

        // Отменяем активную задачу подключения
        connectionTask?.cancel()
        connectionTask = nil

        // Завершаем сессию
        if let conv = conversation {
            conv.endSession()
        }
        conversation = nil

        // Сбрасываем состояние
        status = .disconnected
        isConnecting = false
        audioLevel = 0.0
        mode = .listening
    }

    func beginConversation() {
        let agent = Agent.masha
        // Предотвращаем множественные подключения
        guard !isConnecting else {
            print("⚠️ Connection already in progress, skipping...")
            return
        }

        if status == .connected {
            print("🔌 Disconnecting current session...")
            stopConversation()
            return
        }

        // Сбрасываем предыдущие ошибки и счетчик
        lastError = nil
        connectionRetryCount = 0
        isConnecting = true

        connectionTask = Task {
            await startConnection(agent: agent)
        }
    }

    private func isAgentCorrectionError(_ errorMessage: String) -> Bool {
        let correctionIndicators = [
            "agent_response_correction",
            "Unknown message type",
            "corrected_agent_response",
            "original_agent_response",
        ]

        let errorLower = errorMessage.lowercased()
        return correctionIndicators.contains { errorLower.contains($0.lowercased()) }
    }

    private func shouldRetryConnection(errorMessage: String) -> Bool {
        let retryableErrors = [
            "Socket is not connected",
            "WebSocket error",
            "Connection failed",
            "Network error",
            "timeout",
        ]

        // Не повторяем при ошибках аутентификации, неверных конфигурациях или коррекциях агента
        let nonRetryableErrors = [
            "unauthorized",
            "forbidden",
            "invalid agent",
            "rate limit",
            "agent_response_correction",
            "Unknown message type",
        ]

        let errorLower = errorMessage.lowercased()

        // Сначала проверяем не-повторяемые ошибки
        if nonRetryableErrors.contains(where: { errorLower.contains($0) }) {
            return false
        }

        // Затем проверяем повторяемые
        return retryableErrors.contains { errorLower.contains($0) }
    }
}

// MARK: - Types and Preview
struct Agent {
    let id: String
    let name: String
    let description: String
}

extension Agent {
    static let masha: Self = .init(
        id: "w63wjugjg9aztG1H9JDa",
        name: "Masha",
        description: "AI Assistant"
    )
}
