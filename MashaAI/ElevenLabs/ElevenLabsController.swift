import Combine
import ElevenLabsSDK
import Foundation

// MARK: - Events

enum ErrorEvent {
    case error(message: String, shouldRetry: Bool)
}

enum ElevenLabsEvent {
    case connected(conversationId: String)
    case disconnected
    case connecting
    case statusChanged(ElevenLabsSDK.Status)
    case modeChanged(ElevenLabsSDK.Mode)
    case volumeUpdated(Float)
    case messageReceived(message: String, role: ElevenLabsSDK.Role)
}

// MARK: - Protocol

protocol ElevenLabsControlling {
    var events: AnyPublisher<ElevenLabsEvent, Never> { get }
    var errorEvent: AnyPublisher<ErrorEvent, Never> { get }
    var currentStatus: AnyPublisher<ElevenLabsSDK.Status, Never> { get }
    var currentMode: AnyPublisher<ElevenLabsSDK.Mode, Never> { get }
    var isConnecting: AnyPublisher<Bool, Never> { get }

    func startConversation(with agent: Agent, context: String) async
    func stopConversation()
}

// MARK: - Implementation

final class ElevenLabsController: ElevenLabsControlling {

    // MARK: - Public Properties

    var events: AnyPublisher<ElevenLabsEvent, Never> {
        eventsSubject.eraseToAnyPublisher()
    }

    var errorEvent: AnyPublisher<ErrorEvent, Never> {
        errorEventSubject.eraseToAnyPublisher()
    }

    var currentStatus: AnyPublisher<ElevenLabsSDK.Status, Never> {
        currentStatusSubject.eraseToAnyPublisher()
    }

    var currentMode: AnyPublisher<ElevenLabsSDK.Mode, Never> {
        currentModeSubject.eraseToAnyPublisher()
    }

    var isConnecting: AnyPublisher<Bool, Never> {
        isConnectingSubject.eraseToAnyPublisher()
    }

    // MARK: - Private Properties

    private let eventsSubject = PassthroughSubject<ElevenLabsEvent, Never>()
    private let currentStatusSubject = CurrentValueSubject<ElevenLabsSDK.Status, Never>(.disconnecting)
    private let currentModeSubject = CurrentValueSubject<ElevenLabsSDK.Mode, Never>(.listening)
    private let isConnectingSubject = CurrentValueSubject<Bool, Never>(false)
    private let errorEventSubject = PassthroughSubject<ErrorEvent, Never>()
    private var conversation: ElevenLabsSDK.Conversation?
    private var connectionTask: Task<Void, Never>?
    private var retryCount = 0
    private let maxRetries = 2

    // Store connection parameters for retry
    private var lastAgent: Agent?
    private var lastContext: String?

    deinit {
        stopConversation()
    }

    // MARK: - Public Methods

    func startConversation(with agent: Agent, context: String) async {
        guard !isConnectingSubject.value else {
            print("⚠️ Connection already in progress, skipping...")
            return
        }

        if currentStatusSubject.value == .connected {
            print("🔌 Disconnecting current session...")
            stopConversation()
            return
        }

        eventsSubject.send(.connecting)
        retryCount = 0
        lastAgent = agent
        lastContext = context

        connectionTask = Task {
            await performConnection(agent: agent, context: context)
        }
    }

    func stopConversation() {
        print("🧹 Cleaning up conversation...")

        // Cancel active connection task
        connectionTask?.cancel()
        connectionTask = nil

        // End session
        if let conv = conversation {
            conv.endSession()
        }
        conversation = nil

        // Reset state
        currentStatusSubject.value = .disconnected
        currentModeSubject.value = .listening
        isConnectingSubject.value = false
        retryCount = 0
        lastAgent = nil
        lastContext = nil

        // Notify about disconnection
        eventsSubject.send(.disconnected)
    }

    // MARK: - Private Methods

    private func performConnection(agent: Agent, context: String) async {
        do {
            // Add stabilization delay
            try await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second

            // Check if task was cancelled
            try Task.checkCancellation()

            // Create configuration
            let config = ElevenLabsSDK.SessionConfig(
                agentId: agent.id,
                dynamicVariables: [
                    "recent_topics": .string(context)
                ]
            )

            // Setup callbacks
            let callbacks = createCallbacks()

            // Start session
            conversation = try await ElevenLabsSDK.Conversation.startSession(
                config: config,
                callbacks: callbacks
            )

        } catch {
            await handleConnectionError(error: error)
        }
    }

    private func createCallbacks() -> ElevenLabsSDK.Callbacks {
        var callbacks = ElevenLabsSDK.Callbacks()

        callbacks.onConnect = { [weak self] conversationId in
            DispatchQueue.main.async {
                guard let self else { return }
                print("✅ Connected successfully with ID: \(conversationId)")

                self.currentStatusSubject.value = .connected
                self.isConnectingSubject.value = false
                self.retryCount = 0

                self.eventsSubject.send(.connected(conversationId: conversationId))
            }
        }

        callbacks.onDisconnect = { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async {
                print("🔌 Disconnected")

                let wasConnected = self.currentStatusSubject.value == .connected
                self.currentStatusSubject.value = .disconnected
                self.isConnectingSubject.value = false

                if wasConnected {
                    // Unexpected disconnection
                    self.errorEventSubject.send(.error(message: "Connection lost unexpectedly", shouldRetry: true))
                    self.eventsSubject.send(.disconnected)
                } else {
                    self.eventsSubject.send(.disconnected)
                }
            }
        }

        callbacks.onMessage = { [weak self] message, role in
            self?.eventsSubject.send(.messageReceived(message: message, role: role))
        }

        callbacks.onError = { [weak self] errorMessage, errorCode in
            DispatchQueue.main.async {
                guard let self = self else { return }
                print("❌ Error (\(errorCode ?? -1)): \(errorMessage)")

                // Check if this is an agent correction error (normal when interrupting)
                if self.isAgentCorrectionError(errorMessage) {
                    print("ℹ️ Agent response correction detected - this is normal when interrupting")
                    return
                }

                let shouldRetry =
                self.shouldRetryConnection(errorMessage: errorMessage)
                && self.retryCount < self.maxRetries

                self.errorEventSubject.send(.error(message: errorMessage, shouldRetry: shouldRetry))
                self.eventsSubject.send(.disconnected)

                if shouldRetry {
                    self.scheduleRetry()
                } else {
                    print("💥 Max retries reached or non-retryable error")
                    self.stopConversation()
                }
            }
        }

        callbacks.onStatusChange = { [weak self] newStatus in
            DispatchQueue.main.async {
                guard let self = self else { return }
                print("📊 Status changed: \(newStatus)")

                self.currentStatusSubject.value = newStatus
                self.eventsSubject.send(.statusChanged(newStatus))

                if newStatus == .disconnected {
                    self.isConnectingSubject.value = false
                }
            }
        }

        callbacks.onModeChange = { [weak self] newMode in
            DispatchQueue.main.async {
                guard let self = self else { return }
                print("🎤 Mode changed: \(self.currentModeSubject.value) → \(newMode)")

                self.currentModeSubject.value = newMode
                self.eventsSubject.send(.modeChanged(newMode))
            }
        }

        callbacks.onVolumeUpdate = { [weak self] newVolume in
            DispatchQueue.main.async {
                guard let self = self else { return }
                let clampedVolume = max(0, min(1, newVolume))
                self.eventsSubject.send(.volumeUpdated(clampedVolume))
            }
        }

        return callbacks
    }

    private func handleConnectionError(error: Error) async {
        await MainActor.run {
            print("💥 Failed to start conversation: \(error.localizedDescription)")

            let shouldRetry = retryCount < maxRetries

            self.errorEventSubject.send(.error(message: error.localizedDescription, shouldRetry: shouldRetry))
            self.eventsSubject.send(.disconnected)

            if shouldRetry {
                scheduleRetry()
            } else {
                stopConversation()
            }
        }
    }

    private func scheduleRetry() {
        retryCount += 1
        print("🔄 Will retry connection (\(retryCount)/\(maxRetries)) in 3 seconds...")

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self = self else { return }

            if !self.isConnectingSubject.value && self.currentStatusSubject.value != .connected,
               let agent = self.lastAgent,
               let context = self.lastContext
            {

            Task {
                await self.startConversation(with: agent, context: context)
            }
            }
        }
    }

    // MARK: - Helper Methods

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

        let nonRetryableErrors = [
            "unauthorized",
            "forbidden",
            "invalid agent",
            "rate limit",
            "agent_response_correction",
            "Unknown message type",
        ]

        let errorLower = errorMessage.lowercased()

        // First check non-retryable errors
        if nonRetryableErrors.contains(where: { errorLower.contains($0) }) {
            return false
        }

        // Then check retryable ones
        return retryableErrors.contains { errorLower.contains($0) }
    }
}
