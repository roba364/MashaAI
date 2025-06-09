import ElevenLabsSDK
import SwiftUI
import _Concurrency

struct VoiceChatView: View {
    @ObservedObject
    var viewModel: VoiceChatVM

    var body: some View {
        ZStack {
            GeometryReader { geometry in
                VStack(spacing: 30) {
                    Spacer()

                    OrbView(mode: viewModel.mode, audioLevel: viewModel.audioLevel)

                    VStack(spacing: 12) {
                        Text(viewModel.agents[0].name)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)

                        Text(viewModel.agents[0].description)
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
                        if let error = viewModel.lastError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                                .lineLimit(2)
                        }
                    }

                    CallButton(
                        connectionStatus: viewModel.status,
                        isConnecting: viewModel.isConnecting,
                        action: { viewModel.beginConversation(agent: viewModel.agents[0]) }
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
        .onDisappear {
            print("🏃‍♂️ View disappearing, cleaning up...")
            viewModel.stopConversation()
        }
    }

    private var statusColor: Color {
        switch viewModel.status {
        case .connected:
            return .green
        case .connecting:
            return .orange
        case .disconnecting:
            return .orange
        default:
            return viewModel.isConnecting ? .orange : .gray
        }
    }

    private var statusText: String {
        if viewModel.isConnecting {
            return viewModel.connectionRetryCount > 0 ? "Retrying... (\(viewModel.connectionRetryCount)/2)" : "Connecting..."
        }
        switch viewModel.status {
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
                            Color.pink.opacity(0.4),
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
