import ElevenLabsSDK
import SwiftUI

struct OrbView: View {
    let mode: ElevenLabsSDK.Mode
    let audioLevel: Float

    @State
    private var waveAnimationPhase: Double = 0

    private var scale: CGFloat {
        let baseScale: CGFloat = 1.0
        let maxScale: CGFloat = 1.666
        let scaleFactor = min(CGFloat(audioLevel) * 0.9, maxScale - baseScale)
        return baseScale + scaleFactor
    }

    var body: some View {
        ZStack {
            // Основное изображение
            Image(.sound)
                .resizable()
                .scaledToFill()
                .scaleEffect(scale)
                .animation(.easeInOut(duration: 0.3), value: scale)
        }
    }
}
