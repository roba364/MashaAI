import ElevenLabsSDK
import SwiftUI

struct SpotifyView: View {
    let audioLevel: Float

    private var scale: CGFloat {
        let baseScale: CGFloat = 1.0
        let maxScale: CGFloat = 1.666
        let clampedLevel = max(0, min(audioLevel, 1))
        let scaleFactor = min(CGFloat(clampedLevel) * 0.9, maxScale - baseScale)
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
