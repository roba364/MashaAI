import SwiftUI
import ElevenLabsSDK

struct SpotifyWaveBar: View {
    let delay: Double
    let audioLevel: Float
    let index: Int

    // Высчитываем масштаб opacity на основе audioLevel (как в OrbView)
    private var audioOpacityScale: Double {
        let baseScale: Double = 0.2
        let maxScale: Double = 1.0
        let scaleFactor = min(Double(audioLevel) * 10.0, maxScale - baseScale) // Увеличил множитель до 1.0
        return baseScale + scaleFactor
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let phase = time * 2 + delay // Скорость анимации * 2
            let waveValue = sin(phase)
            let normalizedWave = (waveValue + 1) / 2 // от 0 до 1

            // Комбинируем базовую анимацию волны с реакцией на audioLevel
            let baseOpacity = 0.2
            let animatedOpacity = baseOpacity + (audioOpacityScale - baseOpacity) * normalizedWave

            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(animatedOpacity))
                .frame(width: size(for: index).width, height: size(for: index).height)
                .animation(.easeInOut(duration: 0.1), value: audioLevel) // Плавная реакция на изменение audioLevel
        }
    }

    private func size(for index: Int) -> (width: CGFloat, height: CGFloat) {
        switch index {
        case 0:
            return (width: 80, height: 16)
        case 1:
            return (width: 58, height: 12)
        case 2:
            return (width: 40, height: 8)
        default:
            return (width: 24, height: 6)
        }
    }
}

// Обновленная основная View
struct VoiceChatView: View {

    @ObservedObject
    var viewModel: VoiceChatVM

    var body: some View {
        VStack {
            Image(.masha)
                .resizable()
                .scaledToFill()
                .frame(width: 300, height: 400)
                .padding(.bottom, 270)
                .animateAppear(.optionButton(delay: 0.8))
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
        .onDisappear {
            print("🏃‍♂️ View disappearing, cleaning up...")
            viewModel.stopConversation()
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

            if viewModel.viewState == .connected {
                spotifyWaves()
                    .scaleEffect(1.0)
                    .opacity(1.0)
                    .animation(.easeInOut(duration: 0.3).delay(0.15), value: viewModel.viewState)
            }
        }
    }

    @ViewBuilder
    private func spotifyWaves() -> some View {
        VStack(spacing: 8) { // Горизонтальное расположение как в Spotify
            ForEach(0..<4, id: \.self) { index in
                SpotifyWaveBar(
                    delay: Double(index) * 1.0, // Больше задержки для заметного эффекта
                    audioLevel: viewModel.audioLevel,
                    index: index
                )
            }
        }
        .frame(height: 20)
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
                .animation(.easeInOut(duration: 0.3).delay(viewModel.viewState == .connected ? 0.15 : 0.0), value: viewModel.viewState)
        }
    }
}

#Preview {
    VoiceChatView(viewModel: .init())
}
