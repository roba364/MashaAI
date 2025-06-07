import Foundation

public enum FailableDecodable<T: Decodable>: Decodable {
    case success(T)
    case failure(Error?)

    public var value: T? {
        switch self {
        case .success(let value):
            return value
        case .failure:
            return nil
        }
    }

    public init(from decoder: Decoder) throws {
        do {
            let container = try decoder.singleValueContainer()
            self = .success(try container.decode(T.self))
        } catch {
            self = .failure(error)
        }
    }
}

extension FailableDecodable: Encodable where T: Encodable {

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .success(let value):
            try container.encode(value)
        case .failure:
            try container.encodeNil()
        }
    }
}
