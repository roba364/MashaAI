import SwiftUI

import SwiftUI

struct ContentView: View {

    @StateObject
    private var coordinator: AppCoordinator = AppComponent.shared.appCoordinator()

    var body: some View {
        AppCoordinatorView(coordinator: coordinator)
    }
}
