import SwiftUI

struct ProfileCoordinatorView: View {

    @ObservedObject
    var coordinator: ProfileCoordinator

    var body: some View {
        NavigationStorableView(navigation: coordinator.navigation) {
            coordinator.showProfile()
        }
    }
}
