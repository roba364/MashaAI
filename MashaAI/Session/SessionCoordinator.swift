import Foundation
import MashaUIKit

protocol SessionCoordinatorElementsFactory {
    func voiceChatCoordinator(navigation: VoiceChatCoordinatorNavigation) -> VoiceChatCoordinator
    func profileCoordinator(navigation: ProfileCoordinatorNavigation) -> ProfileCoordinator
}

final class SessionCoordinator: ObservableObject {

    private let elementsFactory: SessionCoordinatorElementsFactory

    init(
        elementsFactory: SessionCoordinatorElementsFactory
    ) {
        self.elementsFactory = elementsFactory
    }

    func onAppear() async {
        // Можно добавить логику, если нужно
    }

    func buildVoiceChatCoordinator() -> VoiceChatCoordinator {
        let coordinator = elementsFactory.voiceChatCoordinator(navigation: .init())

        return coordinator
    }

    func buildProfileCoordinator() -> ProfileCoordinator {
        let coordinator = elementsFactory.profileCoordinator(navigation: .init())

        return coordinator
    }
}
