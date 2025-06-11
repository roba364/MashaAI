import Foundation

class VoiceChatComponent: DIComponent {
    func voiceChatCoordinator(navigation: VoiceChatCoordinatorNavigation) -> VoiceChatCoordinator {
        VoiceChatCoordinator(
            navigation: navigation,
            elementsFactory: self
        )
    }
}

extension VoiceChatComponent: VoiceChatCoordinatorElementsFactory {
    func voiceChatVM() -> VoiceChatVM {
        VoiceChatVM(
            memoryController: resolve()
        )
    }
}
