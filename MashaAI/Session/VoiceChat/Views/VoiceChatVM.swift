import Combine
import ElevenLabsSDK
import Foundation

final class VoiceChatVM: ObservableObject {

    enum ViewState {
        case appearing
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
    var viewState: ViewState = .appearing

    // Новые свойства для отслеживания состояния речи AI
    @Published
    private(set) var isAISpeaking: Bool = false

    private let config = ElevenLabsSDK.SessionConfig(agentId: "w63wjugjg9aztG1H9JDa")
    private let memoryController: MemoryControlling
    private var currentAgentIndex = 0
    private var conversation: ElevenLabsSDK.Conversation?
    private var connectionTask: Task<Void, Never>?

    init(memoryController: MemoryControlling) {
        self.memoryController = memoryController
    }

    func onAppear() async {
        try? await Task.sleep(nanoseconds: 3_000_000_000)  // 1 секунда
        await MainActor.run {
            viewState = .loading
        }
    }

    private func startConnection(agent: Agent) async {
        do {
            let memories = await memoryController.getContextForAI(maxMessages: 100)

            // Увеличиваем задержку для стабильности
            try await Task.sleep(nanoseconds: 1_000_000_000)  // 1 секунда

            // Проверяем, не была ли отменена задача
            try Task.checkCancellation()

            // Упрощенная конфигурация без переопределений
            let config = ElevenLabsSDK.SessionConfig(
                agentId: agent.id,
                dynamicVariables: [
                    "recent_topics": .string(memories)
                ]
            )

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

            callbacks.onMessage = { [weak self] message, role in
                // Используем Task для async операций внутри синхронного колбэка
                Task {
                    do {
                        let memory = Memory(
                            message: message,
                            sender: MemorySender(role: role)
                        )
                        try await self?.memoryController.addMemory(memory)
                    } catch {
                        print("❌ Error saving memory: \(error)")
                    }
                }
            }

            callbacks.onError = { [weak self] errorMessage, errorCode in
                DispatchQueue.main.async {
                    guard let self else { return }
                    print("❌ Error (\(errorCode ?? -1)): \(errorMessage)")

                    //                    self.viewState = .error

                    // Игнорируем ошибки, связанные с коррекцией ответов агента (при перебивании)
                    if self.isAgentCorrectionError(errorMessage) {
                        print("ℹ️ Agent response correction detected - this is normal when interrupting")
                        return
                    }

                    self.lastError = errorMessage

                    // Проверяем, стоит ли повторить попытку
                    if self.shouldRetryConnection(errorMessage: errorMessage) && self.connectionRetryCount < 2
                    {
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

                    let previousMode = self.mode
                    print("🎤 Mode changed: \(previousMode) → \(newMode)")
                    //                    print("📊 Current isAISpeaking: \(self.isAISpeaking)")
                    //                    print(
                    //                        "📊 Raw mode values - Previous: \(String(describing: previousMode)), New: \(String(describing: newMode))"
                    //                    )

                    self.mode = newMode

                    // Отслеживаем переходы состояний для определения начала/конца речи AI
                    self.handleModeTransition(from: previousMode, to: newMode)

                    // Дополнительная проверка текущего состояния
                    self.updateAISpeakingStateBasedOnMode(newMode)

                    print("📊 After transition isAISpeaking: \(self.isAISpeaking)")
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

        // Сбрасываем состояние речи AI
        isAISpeaking = false
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

    // MARK: - Debug Methods

    func simulateAISpeaking() {
        print("🧪 Simulating AI speaking transition")
        let previousMode = mode
        mode = .speaking
        handleModeTransition(from: previousMode, to: .speaking)
        updateAISpeakingStateBasedOnMode(.speaking)
    }

    func simulateAIListening() {
        let previousMode = mode
        mode = .listening
        handleModeTransition(from: previousMode, to: .listening)
        updateAISpeakingStateBasedOnMode(.listening)
    }

    // MARK: - AI Speaking State Tracking

    private func handleModeTransition(
        from previousMode: ElevenLabsSDK.Mode, to newMode: ElevenLabsSDK.Mode
    ) {
        //        print("🔄 Processing mode transition: \(previousMode) → \(newMode)")

        switch (previousMode, newMode) {
        case (.listening, .speaking):
            isAISpeaking = true

        case (.speaking, .listening):
            isAISpeaking = false

        case (.listening, .listening):
            print("🔄 Still listening...")

        case (.speaking, .speaking):
            print("🔄 Still speaking...")

        default:
            print("🔄 Other transition: \(previousMode) → \(newMode)")

            // Добавляем обработку для любых других переходов в .speaking
            if newMode == .speaking && !isAISpeaking {
                isAISpeaking = true
            }

            // Добавляем обработку для любых других переходов в .listening
            if newMode == .listening && isAISpeaking {
                isAISpeaking = false
            }
        }
    }

    private func updateAISpeakingStateBasedOnMode(_ mode: ElevenLabsSDK.Mode) {
        switch mode {
        case .speaking:
            if !isAISpeaking {
                isAISpeaking = true
            }

        case .listening:
            if isAISpeaking {
                isAISpeaking = false
            }
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

extension MemorySender {
    fileprivate init(role: ElevenLabsSDK.Role) {
        switch role {
        case .user:
            self = .user
        case .ai:
            self = .ai
        }
    }
}
