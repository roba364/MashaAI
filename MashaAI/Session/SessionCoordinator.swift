import Foundation
import MashaUIKit

protocol SessionCoordinatorElementsFactory {
    func voiceChatCoordinator(navigation: VoiceChatCoordinatorNavigation) -> VoiceChatCoordinator
}

final class SessionCoordinator: MutableNavigationStackCoordinating {

    enum Screen: Identifiable {
        case voiceChat(VoiceChatCoordinator)

        var id: ObjectIdentifier {
            switch self {
            case let .voiceChat(c): return .init(c)
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
}
