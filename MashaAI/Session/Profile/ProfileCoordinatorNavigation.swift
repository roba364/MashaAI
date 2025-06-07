import SwiftUI

final class ProfileCoordinatorNavigation: NavigationStorable {
    enum Screen {
        case profile(ProfileVM)
        case profileDetails(ProfileDetailsVM)
    }

    @Published
    var path: NavigationPath = NavigationPath()

    init(path: NavigationPath = .init()) {
        self.path = path
    }

    @ViewBuilder
    func view(for screen: Screen) -> some View {
        switch screen {
        case .profile(let vm):
            ProfileView(viewModel: vm)
        case .profileDetails(let vm):
            ProfileDetailsView(viewModel: vm)
        }
    }
}

extension ProfileCoordinatorNavigation.Screen: Hashable {
    static func == (
        lhs: ProfileCoordinatorNavigation.Screen,
        rhs: ProfileCoordinatorNavigation.Screen
    ) -> Bool {
        switch (lhs, rhs) {
        case let (.profile(lvm), .profile(rvm)):
            return lvm === rvm
        case let (.profileDetails(lvm), .profileDetails(rvm)):
            return lvm === rvm
        default:
            return false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .profile(let vm):
            hasher.combine(ObjectIdentifier(vm))
        case .profileDetails(let vm):
            hasher.combine(ObjectIdentifier(vm))
        }
    }
}
