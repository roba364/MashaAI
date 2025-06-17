import Combine
import ElevenLabsSDK
import Foundation
import Utilities

final class VoiceChatVM: ObservableObject {

    enum ViewState {
        case idle
        case connecting
        case loading
        case listening
    }

    // MARK: - Published View States

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
    var viewState: ViewState = .loading

    @Published
    private(set) var isAISpeaking: Bool = false

    // MARK: - Dependencies

    let screenSleepController: ScreenSleepControlling

    private let elevenlabsController: ElevenLabsControlling
    private let memoryController: MemoryControlling

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        elevenlabsController: ElevenLabsControlling,
        memoryController: MemoryControlling,
        screenSleepController: ScreenSleepControlling
    ) {
        self.elevenlabsController = elevenlabsController
        self.memoryController = memoryController
        self.screenSleepController = screenSleepController

        setupEventHandling()
        setupStateBinding()
    }

    // MARK: - Public Methods

    func onAppear() async {
        try? await Task.sleep(nanoseconds: 3_000_000_000)  // 3 seconds
        await MainActor.run {
            viewState = .idle
        }
    }

    func beginConversation() {
        guard !isConnecting else {
            print("⚠️ Connection already in progress, skipping...")
            return
        }

        if status == .connected {
            print("🔌 Disconnecting current session...")
            elevenlabsController.stopConversation()
            return
        }

        // Reset states
        lastError = nil
        connectionRetryCount = 0

        Task {
            let memories = await memoryController.getContextForAI(maxMessages: 100)
            await elevenlabsController.startConversation(with: .masha, context: memories)
        }
    }

    func stopConversation() {
        elevenlabsController.stopConversation()
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

    // MARK: - Private Methods

    private func setupEventHandling() {
        elevenlabsController.events
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handleElevenLabsEvent(event)
            }
            .store(in: &cancellables)
    }

    private func setupStateBinding() {
        elevenlabsController.currentStatus
            .receive(on: DispatchQueue.main)
            .assign(to: \.status, on: self)
            .store(in: &cancellables)

        elevenlabsController.isConnecting
            .receive(on: DispatchQueue.main)
            .assign(to: \.isConnecting, on: self)
            .store(in: &cancellables)
    }

    private func setupErrorOBserver() {
        elevenlabsController.errorEvent
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                switch event {
                case let .error(message, shouldRetry):
                    guard let self else { return }
                    print("❌ Error: \(message), shouldRetry: \(shouldRetry)")
                    lastError = message

                    if shouldRetry {
                        connectionRetryCount += 1

                        // Auto clear error after 5 seconds to return to loading state
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                            guard let self = self else { return }
                            if self.lastError == message {
                                self.lastError = nil
                                if self.status == .disconnected {
                                    self.viewState = .idle
                                }
                            }
                        }
                    } else {
                        // Non-retryable error
                        viewState = .idle
                    }
                }
            }
            .store(in: &cancellables)
    }

    private func handleElevenLabsEvent(_ event: ElevenLabsEvent) {
        switch event {
        case .connected(let conversationId):
            print("✅ Connected successfully with ID: \(conversationId)")
            viewState = .listening
            lastError = nil
            connectionRetryCount = 0

        case .disconnected:
            print("🔌 Disconnected")
            resetViewState()

        case .statusChanged(let newStatus):
            // Status is already bound via publisher
            if newStatus == .disconnected {
                resetViewState()
            }

        case .modeChanged(let newMode):
            let previousMode = mode
            mode = newMode
            handleModeTransition(from: previousMode, to: newMode)
            updateAISpeakingStateBasedOnMode(newMode)

        case .volumeUpdated(let volume):
            audioLevel = volume

        case .messageReceived(let message, let role):
            handleNewMessage(message: message, role: role)

        case .connecting:
            viewState = .connecting
        }
    }

    private func handleNewMessage(message: String, role: ElevenLabsSDK.Role) {
        Task {
            do {
                let memory = Memory(
                    message: message,
                    sender: MemorySender(role: role)
                )
                try await memoryController.addMemory(memory)
            } catch {
                print("❌ Error saving memory: \(error)")
            }
        }
    }

    private func resetViewState() {
        audioLevel = 0.0
        mode = .listening
        isAISpeaking = false

        // If we were connected, this might be unexpected
        if viewState == .listening {
            viewState = .idle
        }
    }

    // MARK: - AI Speaking State Tracking

    private func handleModeTransition(
        from previousMode: ElevenLabsSDK.Mode,
        to newMode: ElevenLabsSDK.Mode
    ) {
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

            // Handle any other transitions to .speaking
            if newMode == .speaking && !isAISpeaking {
                isAISpeaking = true
            }

            // Handle any other transitions to .listening
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
}

// MARK: - Memory Sender Extension

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

