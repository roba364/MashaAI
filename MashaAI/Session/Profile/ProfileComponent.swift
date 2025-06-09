import Foundation

class ProfileComponent: DIComponent {
    func profileCoordinator(navigation: ProfileCoordinatorNavigation) -> ProfileCoordinator {
        ProfileCoordinator(
            navigation: navigation,
            elementsFactory: self
        )
    }
}

extension ProfileComponent: ProfileCoordinatorElementsFactory {
    func profileVM() -> ProfileVM {
        .init()
    }
    
    func profileDetailsVM() -> ProfileDetailsVM {
        .init()
    }
}
