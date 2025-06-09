import Foundation
import SwiftUI

@MainActor
protocol ProfileCoordinatorElementsFactory {
  func profileVM() -> ProfileVM
  func profileDetailsVM() -> ProfileDetailsVM
}

final class ProfileCoordinator: ObservableObject {

  let navigation: ProfileCoordinatorNavigation
  private let elementsFactory: ProfileCoordinatorElementsFactory

  init(
    navigation: ProfileCoordinatorNavigation,
    elementsFactory: ProfileCoordinatorElementsFactory
  ) {
    self.navigation = navigation
    self.elementsFactory = elementsFactory
  }

  @MainActor
  func showProfile() -> some View {
    let viewModel = elementsFactory.profileVM()
    viewModel.output = .init(onDetails: { [weak self] in
      guard let self else { return }

      self.showProfileDetailsVM()
    })

    return navigation.view(for: .profile(viewModel))
  }

  @MainActor
  private func showProfileDetailsVM() {
    let viewModel = elementsFactory.profileDetailsVM()

    navigation.navigateTo(.profileDetails(viewModel))
  }
}
