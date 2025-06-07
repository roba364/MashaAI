import Foundation
import SwiftUI

@MainActor
protocol VoiceChatCoordinatorElementsFactory {
    func voiceChatVM() -> VoiceChatVM
}

final class VoiceChatCoordinator: ObservableObject {

    let navigation: VoiceChatCoordinatorNavigation
    private let elementsFactory: VoiceChatCoordinatorElementsFactory

    init(
        navigation: VoiceChatCoordinatorNavigation,
        elementsFactory: VoiceChatCoordinatorElementsFactory
    ) {
        self.navigation = navigation
        self.elementsFactory = elementsFactory
    }

    @MainActor
    func showMain() -> some View {
        let viewModel = elementsFactory.voiceChatVM()
        return navigation.view(for: .voiceChat(viewModel))
    }
}


