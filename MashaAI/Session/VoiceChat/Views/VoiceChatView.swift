import Combine
import ElevenLabsSDK
import SwiftUI

struct VoiceChatView: View {

    @ObservedObject
    var viewModel: VoiceChatVM

    @Environment(\.playHaptic)
    private var playHaptic

    @State
    private var pulseScale: CGFloat = 1.0
    @State
    private var pulseOpacity: Double = 0.8
    @State
    private var isAnimatingPulse: Bool = false
    @State
    private var pulseAnimationTask: Task<Void, Never>?

    var body: some View {
        VStack {
            content(for: viewModel.viewState)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom, content: bottomView)
        .background {
            Image(.voiceBackground)
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
        }
        .overlay(alignment: .top, content: alertView)
        //    .onReceive(viewModel.$lastError) { error in
        //      guard error != nil else { return }
        //
        //      DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak viewModel] in
        //        viewModel?.viewState = .loading
        //      }
        //    }
        .task {
            await viewModel.onAppear()
        }
        .onDisappear {
            print("🏃‍♂️ View disappearing, cleaning up...")
            // Останавливаем анимации для предотвращения утечек памяти
            stopAllAnimations()
            // Используем новый метод для обработки исчезновения view
            viewModel.onDisappear()
        }
    }

    @ViewBuilder
    private func content(for viewState: VoiceChatVM.ViewState) -> some View {
        switch viewState {
        case .appearing:
            HStack(spacing: 4) {
                Text("Загрузка")
                    .typography(.M1.superBold)
                    .foregroundColor(.white)

                LoadingDotsView()
            }

        case .error, .connected, .loading:
            ZStack {
                LinearGradient(
                    stops: .voiceChatBackground,
                    startPoint: .top,
                    endPoint: .bottom
                )
                .mask {
                    Circle()
                        .fill(.white)
                        .blur(radius: viewModel.isAISpeaking ? 40 : 60)
                        .frame(width: 400)
                        .offset(y: 50)
                }
                .scaleEffect(pulseScale)
                .opacity(pulseOpacity)
                .animation(
                    pulseAnimation,
                    value: isAnimatingPulse
                )
                .onAppear {
                    startPulsing()
                }
                .onChange(of: viewModel.isAISpeaking) { _, newValue in
                    updatePulseAnimation(isAISpeaking: newValue)
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
    }

    private var pulseAnimation: Animation {
        if viewModel.isAISpeaking {
            return .easeInOut(duration: 0.5)
        } else {
            return .easeInOut(duration: 1.2)
        }
    }

    private func startPulsing() {
        updatePulseAnimation(isAISpeaking: viewModel.isAISpeaking)
    }

    private func updatePulseAnimation(isAISpeaking: Bool) {
        // Остановка предыдущей анимации
        pulseAnimationTask?.cancel()

        // Запуск новой анимационной задачи
        pulseAnimationTask = Task { @MainActor in
            while !Task.isCancelled {
                // Установка целевых значений в зависимости от состояния
                let targetScale: CGFloat = isAISpeaking ? 1.15 : 1.05
                let targetOpacity: Double = isAISpeaking ? 1.0 : 0.6
                let duration: Double = isAISpeaking ? 0.5 : 1.2

                // Анимация к максимальным значениям
                pulseScale = targetScale
                pulseOpacity = targetOpacity
                isAnimatingPulse.toggle()

                try? await Task.sleep(for: .seconds(duration))

                if Task.isCancelled { break }

                // Анимация к минимальным значениям
                pulseScale = 1.0
                pulseOpacity = isAISpeaking ? 0.8 : 0.4
                isAnimatingPulse.toggle()

                try? await Task.sleep(for: .seconds(duration))
            }
        }
    }

    @ViewBuilder
    private func bottomView() -> some View {
        switch viewModel.viewState {
        case .appearing:
            EmptyView()
        case .error, .connected, .loading:
            VStack(spacing: 24) {
                indicatorView()
                    .padding(.top, 30)

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
                    .offset(y: 20)
            }
            .animateAppear(.optionButton(delay: 0.4))
        }
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
                SpotifyView(
                    audioLevel: viewModel.audioLevel
                )
                .frame(width: 90, height: 90)
                // Дополнительная анимация при речи AI
                .scaleEffect(viewModel.isAISpeaking ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: viewModel.isAISpeaking)
                //                .overlay(alignment: .trailing) {
                //                    // Статус AI
                //                    Text(statusText)
                //                        .typography(.M1.regular)
                //                        .foregroundStyle(statusColor)
                //                        .multilineTextAlignment(.center)
                //                        .animation(.easeInOut(duration: 0.3), value: viewModel.isAISpeaking)
                //                        .offset(x: 70)
                //                }
            }
            .scaleEffect(viewModel.viewState == .connected ? 1.0 : 0.7)
            .opacity(viewModel.viewState == .connected ? 1.0 : 0.0)
            .animation(
                .easeInOut(duration: 0.3).delay(viewModel.viewState == .connected ? 0.15 : 0.0),
                value: viewModel.viewState
            )
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
        playHaptic(.light)

        switch viewModel.viewState {
        case .loading, .error:
            viewModel.beginConversation()
        case .connected:
            viewModel.stopConversation()
        default:
            break
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

    private func stopAllAnimations() {
        // Отменяем анимационную задачу
        pulseAnimationTask?.cancel()
        pulseAnimationTask = nil

        // Сбрасываем значения анимации
        withAnimation(.linear(duration: 0)) {
            pulseScale = 1.0
            pulseOpacity = 0.8
            isAnimatingPulse = false
        }
    }
}

// MARK: - LoadingDotsView
struct LoadingDotsView: View {
    @State
    private var animationState: Int = 0

    @State
    private var timer: Timer?

    var body: some View {
        HStack(spacing: -5) {
            ForEach(0..<3) { index in
                Text(".")
                    .typography(.M1.superBold)
                    .foregroundColor(.white)
                    .opacity(animationState == index ? 1.0 : 0.5)
                    .scaleEffect(animationState == index ? 1.5 : 1.0)
                    .animation(.easeInOut(duration: 1), value: animationState)
            }
        }
        .offset(y: -5)
        .onAppear {
            startWaveAnimation()
        }
        .onDisappear {
            stopWaveAnimation()
        }
    }

    private func startWaveAnimation() {
        // Останавливаем предыдущий timer если он есть
        stopWaveAnimation()

        timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.4)) {
                animationState = (animationState + 1) % 3
            }
        }
    }

    private func stopWaveAnimation() {
        timer?.invalidate()
        timer = nil
    }
}

#Preview {
    final class MemoryController: MemoryControlling {
        func addMemory(_ memory: Memory) async throws {}

        func getMemories() async -> [Memory] {
            []
        }

        func getRecentMemories(limit: Int) async -> [Memory] {
            []
        }

        func clearMemories() async throws {}

        func observeMemories() -> AnyPublisher<[Memory], Never> {
            Just([]).eraseToAnyPublisher()
        }

        func getContextForAI(maxMessages: Int) async -> String {
            ""
        }
    }

    return VoiceChatView(
        viewModel: VoiceChatVM(
            memoryController: MemoryController()
        )
    )
}
