import Foundation
import MashaUIKit

protocol SessionCoordinatorElementsFactory {
    func voiceChatCoordinator(navigation: VoiceChatCoordinatorNavigation) -> VoiceChatCoordinator
    func profileCoordinator(navigation: ProfileCoordinatorNavigation) -> ProfileCoordinator
}

final class SessionCoordinator: ObservableObject {
    let voiceChatCoordinator: VoiceChatCoordinator
    let profileCoordinator: ProfileCoordinator
    
    private let elementsFactory: SessionCoordinatorElementsFactory
    
    init(
        elementsFactory: SessionCoordinatorElementsFactory
    ) {
        self.elementsFactory = elementsFactory
        self.voiceChatCoordinator = elementsFactory.voiceChatCoordinator(navigation: .init())
        self.profileCoordinator = elementsFactory.profileCoordinator(navigation: .init())
    }
    
    func onAppear() async {
        // Можно добавить логику, если нужно
    }
}
