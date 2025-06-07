import Foundation

@MainActor
protocol OnboardingCoordinatorElementsFactory {
    func firstVM()
    func secondVM()
}

final class OnboardingCoordinator: ObservableObject {

    struct Output {
        let onFinished: () -> Void

        init(
            onFinished: @escaping () -> Void
        ) {
            self.onFinished = onFinished
        }
    }

    var output: Output?

    @Published
    var currentStep: Int = 0

    private let elementsFactory: OnboardingCoordinatorElementsFactory

    init(elementsFactory: OnboardingCoordinatorElementsFactory) {
        self.elementsFactory = elementsFactory
    }

    func next() {
        currentStep += 1

        if currentStep == 3 {
            output?.onFinished()
        }
    }
}
