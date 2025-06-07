import Foundation
import SwiftUI

// protocol ScreenIdentifiable уже определён выше, повторять не нужно

final class SessionCoordinatorNavigation: NavigationStorable {
    enum Screen: ScreenIdentifiable {
        case voiceChat(VoiceChatCoordinator)
        case profile(ProfileCoordinator)

        var screenID: ObjectIdentifier {
            switch self {
            case .voiceChat(let c): return .init(c)
            case .profile(let c): return .init(c)
            }
        }
    }

    @Published
    var path: NavigationPath = NavigationPath()

    init(
        path: NavigationPath = .init()
    ) {
        self.path = path
    }

    @ViewBuilder
    func view(for screen: Screen) -> some View {
        switch screen {
        case .voiceChat(let c):
            VoiceChatCoordinatorView(coordinator: c)
        case .profile(let c):
            ProfileCoordinatorView(coordinator: c)
        }
    }
}
