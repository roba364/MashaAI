import SwiftUI

struct VoiceChatCoordinatorView: View {

    @ObservedObject
    var coordinator: VoiceChatCoordinator

    var body: some View {
        NavigationStorableView(navigation: coordinator.navigation) {
            coordinator.showMain()
        }
        .navigationBarBackButtonHidden()
    }
}
