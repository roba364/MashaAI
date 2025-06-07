import SwiftUI

protocol NavigationStorable: ObservableObject {
    associatedtype Screen: Hashable
    associatedtype DestinationView: View

    var path: NavigationPath { get set }
    func view(for screen: Screen) -> DestinationView
    func navigateTo(_ screen: Screen)
    func navigateBack()
    func popToRoot()
}

extension NavigationStorable {
    func navigateTo(_ screen: Screen) {
        path.append(screen)
    }

    func navigateBack() {
        path.removeLast()
    }

    func popToRoot() {
        path.removeLast(path.count)
    }
}
