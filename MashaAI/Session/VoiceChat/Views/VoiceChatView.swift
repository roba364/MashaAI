import ElevenLabsSDK
import SwiftUI

// Обновленная основная View
struct VoiceChatView: View {

    @ObservedObject
    var viewModel: VoiceChatVM

    var body: some View {
        VStack {
            ZStack {
                LinearGradient(
                    stops: .voiceChatBackground,
                    startPoint: .top,
                    endPoint: .bottom
                )
                .mask {
                    Circle()
                        .fill(.white)
                        .blur(radius: 40)
                        .frame(width: 400)
                        .offset(y: 50)
                }
                .animateAppear(.optionButton(delay: 0.8))

                Image(.masha)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 300, height: 400)
                    .animateAppear(.optionButton(delay: 0.8))
            }
            .padding(.bottom, 180)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .overlay(alignment: .bottom, content: bottomView)
        .background {
            Image(.voiceBackground)
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
        }
        .overlay(alignment: .top, content: alertView)
        .onReceive(viewModel.$lastError) { error in
            guard error != nil else { return }

            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                viewModel.viewState = .loading
            }
        }
        .onReceive(viewModel.$isAISpeaking) { isSpeaking in
            
        }
        .onDisappear {
            print("🏃‍♂️ View disappearing, cleaning up...")
            viewModel.stopConversation()
        }
        .onAppear {
//            // Устанавливаем callbacks для отслеживания речи AI
//            viewModel.onAIStartedSpeaking = {
//                print("🎬 UI: AI started speaking!")
//                // Здесь можно добавить анимации или другие UI эффекты
//            }
//
//            viewModel.onAIStoppedSpeaking = { duration in
//                print("🎬 UI: AI stopped speaking! Duration: \(duration) seconds")
//                // Здесь можно добавить анимации завершения речи
//            }
        }
    }

    @ViewBuilder
    private func bottomView() -> some View {
        VStack(spacing: 24) {
            indicatorView()

            Button {
                handleButtonAction()
            } label: {
                actionButton()
            }
            .buttonStyle(.plain)
            .animateAppear(.optionButton(delay: 0.4))
        }
        .frame(maxWidth: .infinity, alignment: .bottom)
        .frame(height: 280)
        .background {
            Image(.voiceBottom)
                .resizable()
                .scaledToFill()
                .frame(height: 300)
                .offset(y: 15)
        }
        .animateAppear(.optionButton(delay: 0.4))
    }

    @ViewBuilder
    private func indicatorView() -> some View {
        ZStack {
            Text("Привет я Маша,\n давай начнем играть")
                .typography(.M1.bold)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .scaleEffect(viewModel.viewState == .connected ? 0.7 : 1.0)
                .opacity(viewModel.viewState == .connected ? 0.0 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: viewModel.viewState)

            VStack(spacing: 12) {
                OrbView(
                    mode: viewModel.mode,
                    audioLevel: viewModel.audioLevel,
                    isAISpeaking: viewModel.isAISpeaking
                )
                .frame(width: 90, height: 90)
                // Дополнительная анимация при речи AI
                .scaleEffect(viewModel.isAISpeaking ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: viewModel.isAISpeaking)

                // Статус AI
                Text(statusText)
                    .typography(.M1.regular)
                    .foregroundStyle(statusColor)
                    .multilineTextAlignment(.center)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.isAISpeaking)
            }
            .scaleEffect(viewModel.viewState == .connected ? 1.0 : 0.7)
            .opacity(viewModel.viewState == .connected ? 1.0 : 0.0)
            .animation(
                .easeInOut(duration: 0.3).delay(viewModel.viewState == .connected ? 0.15 : 0.0),
                value: viewModel.viewState
            )
        }
    }

    private var statusText: String {
        if viewModel.isAISpeaking {
            return "🗣️ Маша говорит..."
        } else {
            switch viewModel.mode {
            case .listening:
                return "👂 Маша слушает"
            case .speaking:
                return "🎤 Говорите"
            }
        }
    }

    private var statusColor: Color {
        if viewModel.isAISpeaking {
            return .green
        } else {
            switch viewModel.mode {
            case .listening:
                return .blue
            case .speaking:
                return .orange
            }
        }
    }

    @ViewBuilder
    private func alertView() -> some View {
        if case .error = viewModel.viewState {
            VStack {
                Image(.alert)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 280, height: 93)
            }
            .animateAppear(.alertAppear(delay: 0.1))
        }
    }

    private func handleButtonAction() {
        switch viewModel.viewState {
        case .loading, .error:
            viewModel.beginConversation()
        case .connected:
            viewModel.stopConversation()
        }
    }

    @ViewBuilder
    private func actionButton() -> some View {
        ZStack {
            // Start Button
            Image(.startButton)
                .resizable()
                .scaledToFit()
                .frame(width: 202, height: 105)
                .scaleEffect(viewModel.viewState == .connected ? 0.7 : 1.0)
                .opacity(viewModel.viewState == .connected ? 0.0 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: viewModel.viewState)

            // Stop Button
            Image(.stopButton)
                .resizable()
                .scaledToFit()
                .frame(width: 202, height: 105)
                .scaleEffect(viewModel.viewState == .connected ? 1.0 : 0.7)
                .opacity(viewModel.viewState == .connected ? 1.0 : 0.0)
                .animation(
                    .easeInOut(duration: 0.3).delay(viewModel.viewState == .connected ? 0.15 : 0.0),
                    value: viewModel.viewState)
        }
    }
}

#Preview {
    VoiceChatView(viewModel: .init())
}
