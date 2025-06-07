import Foundation

public enum NetworkError: LocalizedError {

    case malformedUrl
    case unexpected
    case generic(message: String)

    public var errorDescription: String? {
        switch self {
        case .malformedUrl:         return Strings.Network.Error.malformed
        case .unexpected:           return Strings.Network.Error.somethingWentWrong
        case .generic(let message): return message
        }
    }
}

extension NetworkError {

    init(from error: Error?) {
        if let error = error {
            self = .generic(message: error.localizedDescription)
        } else {
            self = .unexpected
        }
    }
}
