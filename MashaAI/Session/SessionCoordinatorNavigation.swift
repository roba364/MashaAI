import Foundation
import SwiftUI

final class SessionCoordinatorNavigation: NavigationStorable {
    enum Screen {
        case voiceChat(VoiceChatCoordinator)
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
        }
    }
}

extension SessionCoordinatorNavigation.Screen: Hashable {
    static func == (
        lhs: SessionCoordinatorNavigation.Screen,
        rhs: SessionCoordinatorNavigation.Screen
    ) -> Bool {
        switch (lhs, rhs) {
        case let (.voiceChat(lvm), .voiceChat(rvm)):
            return lvm === rvm
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .voiceChat(let vm):
            hasher.combine(ObjectIdentifier(vm))
        }
    }
}
