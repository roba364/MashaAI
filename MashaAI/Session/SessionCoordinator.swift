import Foundation
import MashaUIKit

protocol SessionCoordinatorElementsFactory {
    func voiceChatCoordinator(navigation: VoiceChatCoordinatorNavigation) -> VoiceChatCoordinator
    func profileCoordinator(navigation: ProfileCoordinatorNavigation) -> ProfileCoordinator
}

final class SessionCoordinator: MutableNavigationStackCoordinating {

    enum Screen: Identifiable {
        case voiceChat(VoiceChatCoordinator)
        case profile(ProfileCoordinator)

        var id: ObjectIdentifier {
            switch self {
            case let .voiceChat(c): return .init(c)
            case let .profile(c): return .init(c)
            }
        }
    }

    @Published
    var stack: [Screen] = []

    private let elementsFactory: SessionCoordinatorElementsFactory

    init(
        elementsFactory: SessionCoordinatorElementsFactory
    ) {
        self.elementsFactory = elementsFactory
    }

    func onAppear() async {
        showVoiceChatCoordinator()
    }

    @MainActor
    func showVoiceChatCoordinator() {
        let coordinator = elementsFactory.voiceChatCoordinator(navigation: .init())

        push(.voiceChat(coordinator))
    }

    @MainActor
    func showProfileCoordinator() {
        let coordinator = elementsFactory.profileCoordinator(navigation: .init())

        push(.profile(coordinator))
    }
}
