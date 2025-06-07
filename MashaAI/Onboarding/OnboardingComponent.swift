import Swinject
import Foundation

class OnboardingComponent: DIComponent {
    func onboardingCoordinator() -> OnboardingCoordinator {
        OnboardingCoordinator(elementsFactory: self)
    }

    // MARK: - Setup

    override func setup(with container: Container) {

    }
}

extension OnboardingComponent: OnboardingCoordinatorElementsFactory {
    func firstVM() {
        //
    }
    
    func secondVM() {
        //
    }
}
