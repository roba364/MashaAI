import SwiftUI
import MashaUIKit

struct ContentView: View {

    @StateObject
    private var coordinator: AppCoordinator = AppComponent.shared.appCoordinator()

    var body: some View {
        AppCoordinatorView(coordinator: coordinator)
            .environment(\.playHaptic, .init(handler: {
                HapticController.shared.play($0)
            }))
    }
}
