import Combine
import ElevenLabsSDK
import Foundation

// MARK: - VoiceChatInteractor
/// Интерактор для обработки side effects в VoiceChat модуле
/// Отвечает за взаимодействие с внешними сервисами и асинхронные операции
final class VoiceChatInteractor: ObservableObject {

    // MARK: - Dependencies
    private let memoryController: MemoryControlling
    private let store: VoiceChatStore

    // MARK: - Private Properties
    private let config = ElevenLabsSDK.SessionConfig(agentId: "w63wjugjg9aztG1H9JDa")
    private var conversation: ElevenLabsSDK.Conversation?
    private var connectionTask: Task<Void, Never>?
    private var retryTask: Task<Void, Never>?
    private var autoReturnTask: Task<Void, Never>?
    // MARK: - Cancellables Storage
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    @MainActor
    init(memoryController: MemoryControlling, store: VoiceChatStore) {
        self.memoryController = memoryController
        self.store = store

        setupActionHandling()
    }

    deinit {
        cleanup()
    }

    // MARK: - Public Methods

    /// Обрабатывает появление view
    func handleViewAppear() async {
        // Задержка перед показом loading состояния (как в оригинале)
        try? await Task.sleep(nanoseconds: 3_000_000_000)  // 3 секунды
        await store.dispatch(.loadingCompleted)
    }

    /// Обрабатывает исчезновение view
    ///
    @MainActor func handleViewDisappear() {
        print("🏃‍♂️ View disappearing, cleaning up...")
        cleanup()
        store.dispatch(.viewDidDisappear)
    }

    /// Начинает разговор с AI
    @MainActor func startConversation() {
        let agent = Agent.masha

        // Сбрасываем предыдущие задачи
        cleanup()

        store.dispatch(.connectionStarted)

        connectionTask = Task {
            await performConnection(agent: agent)
        }
    }

    /// Останавливает разговор
    @MainActor func stopConversation() {
        cleanup()
        store.dispatch(.stopConversation)
    }

    /// Debug методы
    @MainActor func simulateAISpeaking() {
        store.dispatch(.simulateAISpeaking)
    }

    @MainActor func simulateAIListening() {
        store.dispatch(.simulateAIListening)
    }
}

// MARK: - Private Methods
extension VoiceChatInteractor {

    /// Настраивает обработку действий из Store
    @MainActor
    fileprivate func setupActionHandling() {
        // Подписываемся на действия, которые требуют side effects
        store.$state
            .removeDuplicates()
            .sink { [weak self] state in
                self?.handleStateChanges(state)
            }
            .store(in: &cancellables)
    }

    /// Обрабатывает изменения состояния, которые требуют side effects
    func handleStateChanges(_ state: VoiceChatState) {
        // Автоматический возврат к loading после ошибки
        if state.viewState == .error && autoReturnTask == nil {
            scheduleAutoReturnToLoading()
        }

        // Автоматическое переподключение при ошибках
        if let error = state.lastError,
           !state.hasReachedMaxRetries,
           shouldRetryConnection(errorMessage: error),
           retryTask == nil
        {
        scheduleRetryConnection()
        }
    }

    /// Определяет, стоит ли повторять подключение при данной ошибке
    /// (Перенесено из Reducer для использования в Interactor)
    private func shouldRetryConnection(errorMessage: String) -> Bool {
        let retryableErrors = [
            "Socket is not connected",
            "WebSocket error",
            "Connection failed",
            "Network error",
            "timeout",
        ]

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

    /// Выполняет подключение к AI агенту
    func performConnection(agent: Agent) async {
        do {
            let memories = await memoryController.getContextForAI(maxMessages: 100)

            // Увеличиваем задержку для стабильности
            try await Task.sleep(nanoseconds: 1_000_000_000)  // 1 секунда

            // Проверяем, не была ли отменена задача
            try Task.checkCancellation()

            // Конфигурация с памятью
            let config = ElevenLabsSDK.SessionConfig(
                agentId: agent.id,
                dynamicVariables: [
                    "recent_topics": .string(memories)
                ]
            )

            let callbacks = createCallbacks()

            // Пытаемся установить соединение
            conversation = try await ElevenLabsSDK.Conversation.startSession(
                config: config,
                callbacks: callbacks
            )

        } catch {
            await MainActor.run {
                store.dispatch(.connectionError(message: error.localizedDescription))
            }
        }
    }

    /// Создает колбэки для ElevenLabs SDK
    func createCallbacks() -> ElevenLabsSDK.Callbacks {
        var callbacks = ElevenLabsSDK.Callbacks()

        callbacks.onConnect = { [weak self] conversationId in
            DispatchQueue.main.async {
                self?.store.dispatch(.connectionEstablished(conversationId: conversationId))
            }
        }

        callbacks.onDisconnect = { [weak self] in
            DispatchQueue.main.async {
                self?.store.dispatch(.connectionDisconnected)
            }
        }

        callbacks.onMessage = { [weak self] message, role in
            // Используем Task для async операций в синхронном колбэке
            Task {
                do {
                    let memory = Memory(
                        message: message,
                        sender: MemorySender(role: role)
                    )
                    try await self?.memoryController.addMemory(memory)

                    await MainActor.run {
                        self?.store.dispatch(.messageReceived(message: message, role: role))
                    }
                } catch {
                    print("❌ Error saving memory: \(error)")
                }
            }
        }

        callbacks.onError = { [weak self] errorMessage, errorCode in
            DispatchQueue.main.async {
                self?.store.dispatch(.connectionError(message: errorMessage))
            }
        }

        callbacks.onStatusChange = { [weak self] newStatus in
            DispatchQueue.main.async {
                self?.store.dispatch(.statusChanged(newStatus))
            }
        }

        callbacks.onModeChange = { [weak self] newMode in
            DispatchQueue.main.async {
                guard let self = self else { return }
                let previousMode = self.store.state.mode
                self.store.dispatch(.modeChanged(from: previousMode, to: newMode))
            }
        }

        callbacks.onVolumeUpdate = { [weak self] newVolume in
            DispatchQueue.main.async {
                self?.store.dispatch(.volumeUpdated(newVolume))
            }
        }

        return callbacks
    }

    /// Планирует автоматический возврат к loading после ошибки
    func scheduleAutoReturnToLoading() {
        autoReturnTask = Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000)  // 5 секунд

            if !Task.isCancelled {
                await MainActor.run {
                    store.dispatch(.autoReturnToLoading)
                }
            }

            autoReturnTask = nil
        }
    }

    /// Планирует повторное подключение
    func scheduleRetryConnection() {
        retryTask = Task {
            // Инкремент счетчика
            await MainActor.run {
                store.dispatch(.incrementRetryCount)
            }

            print("🔄 Will retry connection in 3 seconds...")
            try? await Task.sleep(nanoseconds: 3_000_000_000)  // 3 секунды

            if !Task.isCancelled {
                await MainActor.run {
                    let state = store.state
                    if !state.isConnecting && !state.isConnected {
                        store.dispatch(.retryConnection)
                        // Перезапускаем подключение
                        connectionTask = Task {
                            await performConnection(agent: Agent.masha)
                        }
                    }
                }
            }

            retryTask = nil
        }
    }

    /// Очистка ресурсов
    func cleanup() {
        // Отменяем все активные задачи
        connectionTask?.cancel()
        connectionTask = nil

        retryTask?.cancel()
        retryTask = nil

        autoReturnTask?.cancel()
        autoReturnTask = nil

        // Завершаем сессию
        if let conv = conversation {
            conv.endSession()
        }
        conversation = nil
    }
}

// MARK: - Helper Extensions
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

// MARK: - Agent Model
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
