import SwiftUI
import ElevenLabsSDK

struct VoiceChatView: View {
    @StateObject var viewModel: VoiceChatVM

    var body: some View {
        VStack {
            ConversationalAIExampleView()
        }
//        .task {
//            await viewModel.onAppear()
//        }
    }
}

import SwiftUI
import _Concurrency

struct OrbView: View {
    let mode: ElevenLabsSDK.Mode
    let audioLevel: Float

    private var iconName: String {
        switch mode {
        case .listening:
            return "waveform"
        case .speaking:
            return "speaker.wave.2.fill"
        }
    }

    private var scale: CGFloat {
        let baseScale: CGFloat = 1.0
        let maxScale: CGFloat = 1.3
        let scaleFactor = min(CGFloat(audioLevel) * 0.5, maxScale - baseScale)
        return baseScale + scaleFactor
    }

    var body: some View {
        ZStack {
            // Заменяем отсутствующее изображение orb на кастомный orb
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.8),
                            Color.purple.opacity(0.6),
                            Color.pink.opacity(0.4)
                        ]),
                        center: .center,
                        startRadius: 20,
                        endRadius: 75
                    )
                )
                .frame(width: 150, height: 150)
                .blur(radius: 1)
                .scaleEffect(scale)
                .animation(.easeInOut(duration: 0.3), value: scale)

            // Внутренний круг
            Circle()
                .fill(.white.opacity(0.9))
                .frame(width: 48, height: 48)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                .scaleEffect(scale)
                .animation(.spring(response: 0.15, dampingFraction: 0.7), value: scale)

            // Mode icon
            Image(systemName: iconName)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.black)
                .scaleEffect(scale)
                .animation(.spring(response: 0.15, dampingFraction: 0.7), value: scale)
        }
    }
}

struct ConversationalAIExampleView: View {
    @State private var currentAgentIndex = 0
    @State private var conversation: ElevenLabsSDK.Conversation?
    @State private var audioLevel: Float = 0.0
    @State private var mode: ElevenLabsSDK.Mode = .listening
    @State private var status: ElevenLabsSDK.Status = .disconnected
    @State private var isConnecting = false
    @State private var connectionRetryCount = 0
    @State private var lastError: String?
    @State private var connectionTask: Task<Void, Never>?

    let agents = [
        Agent(
            id: "w63wjugjg9aztG1H9JDa",
            name: "Masha",
            description: "AI Assistant"
        )
    ]

    private func cleanupConversation() {
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

    private func beginConversation(agent: Agent) {
        // Предотвращаем множественные подключения
        guard !isConnecting else {
            print("⚠️ Connection already in progress, skipping...")
            return
        }

        if status == .connected {
            print("🔌 Disconnecting current session...")
            cleanupConversation()
            return
        }

        // Сбрасываем предыдущие ошибки и счетчик
        lastError = nil
        connectionRetryCount = 0
        isConnecting = true

        connectionTask = Task {
            await performConnection(agent: agent)
        }
    }

    private func performConnection(agent: Agent) async {
        do {
            print("🚀 Starting conversation session (attempt \(connectionRetryCount + 10))...")

            // Увеличиваем задержку для стабильности
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 секунда

            // Проверяем, не была ли отменена задача
            try Task.checkCancellation()

            // Упрощенная конфигурация без переопределений
            let config = ElevenLabsSDK.SessionConfig(agentId: agent.id)

            var callbacks = ElevenLabsSDK.Callbacks()

            callbacks.onConnect = { conversationId in
                DispatchQueue.main.async {
                    print("✅ Connected successfully with ID: \(conversationId)")
                    status = .connected
                    isConnecting = false
                    connectionRetryCount = 0
                    lastError = nil
                }
            }

            callbacks.onDisconnect = {
                DispatchQueue.main.async {
                    print("🔌 Disconnected")
                    if status == .connected {
                        // Неожиданное отключение
                        lastError = "Connection lost unexpectedly"
                    }
                    cleanupConversation()
                }
            }

            callbacks.onMessage = { message, role in
                DispatchQueue.main.async {
                    print("💬 Message (\(role)): \(message)")
                }
            }

            callbacks.onError = { errorMessage, errorCode in
                DispatchQueue.main.async {
                    print("❌ Error (\(errorCode ?? -1)): \(errorMessage)")

                    // Игнорируем ошибки, связанные с коррекцией ответов агента (при перебивании)
                    if isAgentCorrectionError(errorMessage) {
                        print("ℹ️ Agent response correction detected - this is normal when interrupting")
                        return
                    }

                    lastError = errorMessage

                    // Проверяем, стоит ли повторить попытку
                    if shouldRetryConnection(errorMessage: errorMessage) && connectionRetryCount < 2 {
                        connectionRetryCount += 1
                        print("🔄 Will retry connection (\(connectionRetryCount)/2) in 3 seconds...")

                        // Увеличиваем интервал между попытками
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            if !isConnecting && status != .connected {
                                connectionTask = Task {
                                    await performConnection(agent: agent)
                                }
                            }
                        }
                    } else {
                        print("💥 Max retries reached or non-retryable error")
                        cleanupConversation()
                    }
                }
            }

            callbacks.onStatusChange = { newStatus in
                DispatchQueue.main.async {
                    print("📊 Status changed: \(newStatus)")
                    status = newStatus

                    if newStatus == .disconnected {
                        isConnecting = false
                    }
                }
            }

            callbacks.onModeChange = { newMode in
                DispatchQueue.main.async {
                    print("🎤 Mode changed: \(newMode)")
                    mode = newMode
                }
            }

            callbacks.onVolumeUpdate = { newVolume in
                DispatchQueue.main.async {
                    audioLevel = max(0, min(1, newVolume))
                }
            }

            // Пытаемся установить соединение
            conversation = try await ElevenLabsSDK.Conversation.startSession(
                config: config,
                callbacks: callbacks
            )

        } catch {
            DispatchQueue.main.async {
                print("💥 Failed to start conversation: \(error.localizedDescription)")
                lastError = error.localizedDescription
                cleanupConversation()
            }
        }
    }


    private func isAgentCorrectionError(_ errorMessage: String) -> Bool {
        let correctionIndicators = [
            "agent_response_correction",
            "Unknown message type",
            "corrected_agent_response",
            "original_agent_response"
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
            "timeout"
        ]

        // Не повторяем при ошибках аутентификации, неверных конфигурациях или коррекциях агента
        let nonRetryableErrors = [
            "unauthorized",
            "forbidden",
            "invalid agent",
            "rate limit",
            "agent_response_correction",
            "Unknown message type"
        ]

        let errorLower = errorMessage.lowercased()

        // Сначала проверяем не-повторяемые ошибки
        if nonRetryableErrors.contains(where: { errorLower.contains($0) }) {
            return false
        }

        // Затем проверяем повторяемые
        return retryableErrors.contains { errorLower.contains($0) }
    }

    var body: some View {
        ZStack {
            GeometryReader { geometry in
                VStack(spacing: 30) {
                    Spacer()

                    OrbView(mode: mode, audioLevel: audioLevel)

                    VStack(spacing: 12) {
                        Text(agents[currentAgentIndex].name)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)

                        Text(agents[currentAgentIndex].description)
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        // Статус соединения
                        HStack(spacing: 8) {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 10, height: 10)
                            Text(statusText)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        // Показываем ошибки
                        if let error = lastError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                                .lineLimit(2)
                        }
                    }

                    if agents.count > 1 {
                        HStack(spacing: 8) {
                            ForEach(0..<agents.count, id: \.self) { index in
                                Circle()
                                    .fill(index == currentAgentIndex ? Color.black : Color.gray.opacity(0.3))
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }

                    Spacer()

                    CallButton(
                        connectionStatus: status,
                        isConnecting: isConnecting,
                        action: { beginConversation(agent: agents[currentAgentIndex]) }
                    )
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }

            // Заменяем отсутствующий logo на текст или системную иконку
            VStack {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.title2)
                        .foregroundColor(.black)
                    Text("MashaAI")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                }
                .padding(.top, 16)

                Spacer()
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    guard status != .connected && !isConnecting && agents.count > 1 else { return }

                    if value.translation.width < -50 && currentAgentIndex < agents.count - 1 {
                        currentAgentIndex += 1
                    } else if value.translation.width > 50 && currentAgentIndex > 0 {
                        currentAgentIndex -= 1
                    }
                }
        )
        .onDisappear {
            print("🏃‍♂️ View disappearing, cleaning up...")
            cleanupConversation()
        }
    }

    private var statusColor: Color {
        switch status {
        case .connected:
            return .green
        case .connecting:
            return .orange
        case .disconnecting:
            return .orange
        default:
            return isConnecting ? .orange : .gray
        }
    }

    private var statusText: String {
        if isConnecting {
            return connectionRetryCount > 0 ? "Retrying... (\(connectionRetryCount)/2)" : "Connecting..."
        }
        switch status {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting"
        case .disconnecting:
            return "Disconnecting"
        default:
            return "Disconnected"
        }
    }
}

// MARK: - Call Button Component
struct CallButton: View {
    let connectionStatus: ElevenLabsSDK.Status
    let isConnecting: Bool
    let action: () -> Void

    private var buttonIcon: String {
        if isConnecting {
            return "phone.arrow.up.right.fill"
        }

        switch connectionStatus {
        case .connected:
            return "phone.down.fill"
        case .connecting:
            return "phone.arrow.up.right.fill"
        case .disconnecting:
            return "phone.arrow.down.left.fill"
        default:
            return "phone.fill"
        }
    }

    private var buttonColor: Color {
        if isConnecting {
            return .orange
        }

        switch connectionStatus {
        case .connected:
            return .red
        case .connecting, .disconnecting:
            return .gray
        default:
            return .blue
        }
    }

    private var isButtonDisabled: Bool {
        return connectionStatus == .connecting || connectionStatus == .disconnecting
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(buttonColor)
                    .frame(width: 70, height: 70)
                    .shadow(color: buttonColor.opacity(0.3), radius: isButtonDisabled ? 2 : 8, x: 0, y: 4)
                    .opacity(isButtonDisabled ? 0.7 : 1.0)

                if isConnecting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: buttonIcon)
                        .font(.system(size: 26, weight: .medium))
                        .foregroundColor(.white)
                }
            }
        }
        .disabled(isButtonDisabled)
        .padding(.bottom, 50)
    }
}

// MARK: - Types and Preview
struct Agent {
    let id: String
    let name: String
    let description: String
}

struct ConvAIExampleView_Previews: PreviewProvider {
    static var previews: some View {
        ConversationalAIExampleView()
    }
}
