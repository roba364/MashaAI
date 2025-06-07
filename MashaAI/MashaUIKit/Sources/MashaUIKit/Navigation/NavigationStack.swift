import Foundation

public class NaviationStack<Screen: Identifiable>: MutableNavigationStackCoordinating {
    @Published
    public var stack: [Screen]

    public init(stack: [Screen] = []) {
        self.stack = stack
    }
}
