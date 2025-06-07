import SwiftUI

struct NavigationStorableView<Content: View, Navigation: NavigationStorable>: View {

    @ObservedObject
    var navigation: Navigation
    // Our root view content
    private let content: Content

    init(navigation: Navigation,
         @ViewBuilder content: @escaping () -> Content
    ) {
        self.navigation = navigation
        self.content = content()
    }

    var body: some View {
        NavigationStack(path: $navigation.path) {
            content
                .navigationDestination(for: Navigation.Screen.self) { screen in
                    navigation.view(for: screen)
                }
        }
    }
}
