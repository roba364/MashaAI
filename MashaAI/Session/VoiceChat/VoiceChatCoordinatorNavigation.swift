import SwiftUI

// protocol ScreenIdentifiable уже определён выше, повторять не нужно

final class VoiceChatCoordinatorNavigation: NavigationStorable {
    enum Screen: ScreenIdentifiable {
        case voiceChat(VoiceChatVM)

        var screenID: ObjectIdentifier {
            switch self {
            case .voiceChat(let vm): return ObjectIdentifier(vm)
            }
        }
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
