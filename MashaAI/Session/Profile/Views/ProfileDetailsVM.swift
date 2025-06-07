import Foundation

final class ProfileDetailsVM: ObservableObject {
    struct Output {
        let onBack: () -> Void
    }

    var output: Output?
}
