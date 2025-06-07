import SwiftUI

public struct CloseButton: View {

    public enum Size {
        case small, medium
    }

    @Environment(\.playHaptic)
    private var playHaptic

    private let size: Size
    private let action: @MainActor () -> Void

    public init(
        size: Size = .small,
        action: @MainActor @escaping () -> Void
    ) {
        self.size = size
        self.action = action
    }

    public var body: some View {
        Button {
            playHaptic(.medium)
            action()
        } label: {
            circle()
                .overlay(content)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    var content: some View {
        Image("close")
            .resizable()
            .scaledToFit()
            .frame(width: sizeAsFit().img, height: sizeAsFit().img)
            .transition(.opacity.animation(.default))
    }

    @ViewBuilder
    private func circle() -> some View {
        ZStack {
            Color.palette.closeBtn.opacity(0.24)

//            BackdropBlurView(radius: 8)
        }
        .clipShape(Circle())
        .frame(width: sizeAsFit().circle, height: sizeAsFit().circle)
    }

    private func sizeAsFit() -> (img: CGFloat, circle: CGFloat) {
        switch size {
        case .small:
            return (img: 12, circle: 30)
        case .medium:
            return (img: 16, circle: 40)
        }
    }
}
