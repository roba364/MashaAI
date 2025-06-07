import Foundation

final class ProfileVM: ObservableObject {

    struct Output {
        let onDetails: () -> Void
    }

    var output: Output?

    func onDetails() {
        output?.onDetails()
    }
}
