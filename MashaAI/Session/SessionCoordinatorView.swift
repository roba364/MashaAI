import MashaUIKit
import SwiftUI

struct SessionCoordinatorView: View {

    @ObservedObject
    var coordinator: SessionCoordinator

    @State private var selectedTab: Tab = .voice

    enum Tab: Hashable {
        case voice
        case profile
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            VoiceChatCoordinatorView(coordinator: coordinator.buildVoiceChatCoordinator())
                .tabItem {
                    Label("Voice", systemImage: "mic.fill")
                }
                .tag(Tab.voice)

            ProfileCoordinatorView(coordinator: coordinator.buildProfileCoordinator())
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
                .tag(Tab.profile)
        }
        .onAppear {
            Task {
                await coordinator.onAppear()
            }
        }
    }
}
