import Foundation
import SwiftUI

@MainActor
protocol ProfileCoordinatorElementsFactory {
    func profileVM() -> ProfileVM
}

final class ProfileCoordinator: ObservableObject {

    let navigation: ProfileCoordinatorNavigation
    private let elementsFactory: ProfileCoordinatorElementsFactory

    init(
        navigation: ProfileCoordinatorNavigation,
        elementsFactory: ProfileCoordinatorElementsFactory
    ) {
        self.navigation = navigation
        self.elementsFactory = elementsFactory
    }

    @MainActor
    func showProfile() -> some View {
        let viewModel = elementsFactory.profileVM()
        return navigation.view(for: .profile(viewModel))
    }
}
