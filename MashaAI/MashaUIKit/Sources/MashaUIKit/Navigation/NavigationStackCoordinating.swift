import Foundation
import Combine

@MainActor
public protocol NavigationStackCoordinating: ObservableObject {
    associatedtype Screen: Identifiable

    var stack: [Screen] { get }

    func onBack()
}

@MainActor
public protocol MutableNavigationStackCoordinating: NavigationStackCoordinating {

    var stack: [Screen] { get set }
}

public extension MutableNavigationStackCoordinating {
    func push(_ screen: Screen) {
        stack.append(screen)
    }

    func pop() {
        _ = stack.popLast()
    }

    func popToRoot() {
        stack.removeAll()
    }

    func onBack() {
        pop()
    }

    var stepIndex: Int? { stack.indices.last }
}
