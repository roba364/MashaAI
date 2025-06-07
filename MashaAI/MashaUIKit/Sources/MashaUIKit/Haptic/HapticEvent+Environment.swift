import SwiftUI

private struct HapticEventEnvironmentKey: EnvironmentKey {

    public static var defaultValue: HapticEvent?
}

public extension EnvironmentValues {

    var hapticEvent: HapticEvent? {
        get { self[HapticEventEnvironmentKey.self] }
        set { self[HapticEventEnvironmentKey.self] = newValue }
    }
}

public extension View {
    func hapticEvent(_ event: HapticEvent?) -> some View {
        environment(\.hapticEvent, event)
    }
}
