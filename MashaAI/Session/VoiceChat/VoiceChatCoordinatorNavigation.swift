import SwiftUI

final class VoiceChatCoordinatorNavigation: NavigationStorable {
    enum Screen {
        case voiceChat(VoiceChatVM)
    }

    @Published
    var path: NavigationPath = NavigationPath()

    init(path: NavigationPath = .init()) {
        self.path = path
    }

    @ViewBuilder
    func view(for screen: Screen) -> some View {
        switch screen {
        case .voiceChat(let vm):
            VoiceChatView(viewModel: vm)
        }
    }
}

extension VoiceChatCoordinatorNavigation.Screen: Hashable {
    static func == (
        lhs: VoiceChatCoordinatorNavigation.Screen,
        rhs: VoiceChatCoordinatorNavigation.Screen
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
