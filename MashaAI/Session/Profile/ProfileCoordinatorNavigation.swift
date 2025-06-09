import SwiftUI

final class ProfileCoordinatorNavigation: NavigationStorable {
    enum Screen: ScreenIdentifiable {
        case profile(ProfileVM)
        case profileDetails(ProfileDetailsVM)
        
        var screenID: ObjectIdentifier {
            switch self {
            case .profile(let vm): return .init(vm)
            case .profileDetails(let vm): return .init(vm)
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
        case .profile(let vm):
            ProfileView(viewModel: vm)
        case .profileDetails(let vm):
            ProfileDetailsView(viewModel: vm)
        }
    }
}
