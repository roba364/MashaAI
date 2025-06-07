import SwiftUI

private struct HapticActionEnvironmentKey: EnvironmentKey {
    public static var defaultValue: PlayHapticAction {
        .init(handler: { _ in })
    }
}

public extension EnvironmentValues {
    var playHaptic: PlayHapticAction {
        get { self[HapticActionEnvironmentKey.self] }
        set { self[HapticActionEnvironmentKey.self] = newValue }
    }
}

public struct PlayHapticAction {
    let handler: (HapticEvent) -> Void

    public init(handler: @escaping (HapticEvent) -> Void) {
        self.handler = handler
    }

    public func callAsFunction(_ haptic: HapticEvent) {
        handler(haptic)
    }
}
