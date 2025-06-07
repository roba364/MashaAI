import Foundation

enum Strings {
    enum Network {
        enum Error {
            static let malformed = "malformed url".localized
            static let somethingWentWrong = "something went wrong".localized
        }
    }
}

extension String {
    var localized: String {
        NSLocalizedString(
            self,
            comment: "\(self) could not be found in Localizable.strings"
        )
    }
}
