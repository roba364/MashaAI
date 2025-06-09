//import SwiftUI
//import ElevenLabsSDK
//
//struct OrbView: View {
//    let mode: ElevenLabsSDK.Mode
//    let audioLevel: Float
//
//    @State private var waveAnimationPhase: Double = 0
//
//    private var iconName: String {
//        switch mode {
//        case .listening:
//            return "waveform"
//        case .speaking:
//            return "speaker.wave.2.fill"
//        }
//    }
//
//    private var scale: CGFloat {
//        let baseScale: CGFloat = 1.0
//        let maxScale: CGFloat = 1.3
//        let scaleFactor = min(CGFloat(audioLevel) * 0.5, maxScale - baseScale)
//        return baseScale + scaleFactor
//    }
//
//    var body: some View {
//        ZStack {
//            // Заменяем отсутствующее изображение orb на кастомный orb
//            Circle()
//                .fill(
//                    RadialGradient(
//                        gradient: Gradient(colors: [
//                            Color.blue.opacity(0.8),
//                            Color.purple.opacity(0.6),
//                            Color.pink.opacity(0.4),
//                        ]),
//                        center: .center,
//                        startRadius: 20,
//                        endRadius: 75
//                    )
//                )
//                .frame(width: 150, height: 150)
//                .blur(radius: 1)
//                .scaleEffect(scale)
//                .animation(.easeInOut(duration: 0.3), value: scale)
//
//            // Spotify-style waves (только когда пользователь говорит)
//            if mode == .speaking {
//                spotifyWaves()
//            }
//
//            // Внутренний круг
//            Circle()
//                .fill(.white.opacity(0.9))
//                .frame(width: 48, height: 48)
//                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
//                .scaleEffect(scale)
//                .animation(.spring(response: 0.15, dampingFraction: 0.7), value: scale)
//
//            // Mode icon
//            Image(systemName: iconName)
//                .font(.system(size: 24, weight: .medium))
//                .foregroundColor(.black)
//                .scaleEffect(scale)
//                .animation(.spring(response: 0.15, dampingFraction: 0.7), value: scale)
//        }
//        .onAppear {
//            startWaveAnimation()
//        }
//    }
//
//    @ViewBuilder
//    private func spotifyWaves() -> some View {
//        HStack(spacing: 4) {
//            ForEach(0..<4, id: \.self) { index in
//                SpotifyWaveBar(
//                    animationPhase: waveAnimationPhase,
//                    delay: Double(index) * 0.2,
//                    audioLevel: audioLevel,
//                    index: index
//                )
//            }
//        }
//        .frame(width: 90, height: 90)
//    }
//
//    private func startWaveAnimation() {
//        withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false)) {
//            waveAnimationPhase = 2 * .pi
//        }
//    }
//}
//
//struct SpotifyWaveBar: View {
//    let animationPhase: Double
//    let delay: Double
//    let audioLevel: Float
//    let index: Int
//
//    private var waveOpacity: Double {
//        let baseOpacity = 0.2
//        let maxOpacity = 1.0
//
//        // Создаем синусоидальную волну с учетом фазы и задержки
//        let waveValue = sin(animationPhase + delay * 2)
//        let normalizedWave = (waveValue + 1) / 2 // Нормализуем от 0 до 1
//
//        // Добавляем влияние audioLevel для более реалистичного эффекта
//        let audioFactor = min(CGFloat(audioLevel) * 0.3, 0.5)
//        let finalOpacity = baseOpacity + (maxOpacity - baseOpacity) * (normalizedWave + Double(audioFactor))
//
//        return min(finalOpacity, maxOpacity)
//    }
//
//    private var waveHeight: CGFloat {
//        let baseHeight: CGFloat = 4
//        let maxHeight: CGFloat = 20
//
//        // Высота волны также следует синусоидальному паттерну
//        let waveValue = sin(animationPhase + delay * 2)
//        let normalizedWave = (waveValue + 1) / 2
//
//        // Добавляем влияние audioLevel
//        let audioFactor = min(CGFloat(audioLevel) * 0.4, 0.6)
//        let finalHeight = baseHeight + (maxHeight - baseHeight) * (normalizedWave + audioFactor)
//
//        return min(finalHeight, maxHeight)
//    }
//
//    var body: some View {
//        RoundedRectangle(cornerRadius: 2)
//            .fill(Color.white.opacity(waveOpacity))
//            .frame(width: size(for: index).width, height: size(for: index).height)
//            .animation(.easeInOut(duration: 0.1), value: waveOpacity)
//            .animation(.easeInOut(duration: 0.1), value: waveHeight)
//    }
//
//    private func size(for index: Int) -> (width: CGFloat, height: CGFloat) {
//        switch index {
//        case 0:
//            return (width: 80, height: 16)
//        case 1:
//            return (width: 58, height: 12)
//        case 2:
//            return (width: 40, height: 8)
//        default:
//            return (width: 24, height: 4)
//        }
//    }
//}
