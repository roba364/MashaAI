import SwiftUI
import MashaUIKit

struct SessionCoordinatorView: View {

    @ObservedObject
    var coordinator: SessionCoordinator

    var body: some View {
        NavigationStackView(coordinator) {
            view(for: $0)
        }
        .task {
            await coordinator.onAppear()
        }
    }

    @ViewBuilder
    private func view(for screen: SessionCoordinator.Screen) -> some View {
        switch screen {
        case .voiceChat(let c):
            VoiceChatCoordinatorView(coordinator: c)
        case .profile(let c):
            ProfileCoordinatorView(coordinator: c)
        }
    }
}
