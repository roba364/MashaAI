import SwiftUI
import ElevenLabsSDK

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
