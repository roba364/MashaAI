import SwiftUI

public struct BackButton: View {

    public enum Size {
        case medium
        case large
    }

    @Environment(\.isEnabled)
    private var isEnabled

    @Environment(\.navigationBarStyle)
    private var navigationBarStyle

    @Environment(\.playHaptic)
    private var playHaptic

    private let size: Size
    private let action: () -> Void

    public init(
        size: Size = .medium,
        action: @escaping () -> Void
    ) {
        self.size = size
        self.action = action
    }

    public var body: some View {
        Button {
            playHaptic(.navBarBtn)
            action()
        } label: {
            Image("chevron_backward_max")
                .scaledToFit()
                .padding(.vertical, 16)
                .frame(width: buttonSize.width, height: buttonSize.height)
                .background {
                    Circle()
                        .fill(fillColor)
                }
                .opacity(isEnabled ? 1 : 0.2)
                .animation(.default, value: isEnabled)
                .transition(.opacity.animation(.default))
        }
    }

    private var fillColor: Color {
        switch navigationBarStyle.appearence {
        case .dark: return .white.opacity(0.05)
        case .light: return .clear
        }
    }

    private var buttonSize: CGSize {
        Self.size(for: size)
    }

    private static func size(for size: Size) -> CGSize {
        switch size {
        case .medium:
            return CGSize(width: 34, height: 34)
        case .large:
            return CGSize(width: 54, height: 54)
        }
    }
}

struct BackButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            BackButton(action: {})
            BackButton(action: {})
                .disabled(true)
        }
    }
}
