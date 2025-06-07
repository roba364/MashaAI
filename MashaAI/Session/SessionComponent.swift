import Foundation

class SessionComponent: DIComponent {
    func sessionCoordinator() -> SessionCoordinator {
        SessionCoordinator(
            elementsFactory: self
        )
    }
}

extension SessionComponent: SessionCoordinatorElementsFactory {
    func voiceChatCoordinator(navigation: VoiceChatCoordinatorNavigation) -> VoiceChatCoordinator {
        VoiceChatComponent(parent: self)
            .voiceChatCoordinator(navigation: navigation)
    }

    func profileCoordinator(navigation: ProfileCoordinatorNavigation) -> ProfileCoordinator {
        ProfileComponent(parent: self)
            .profileCoordinator(navigation: navigation)
    }
}
