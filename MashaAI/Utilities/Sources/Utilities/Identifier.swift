import Foundation

/// Type safe abstract identifier
public struct Identifier<T>: Hashable,
                             RawRepresentable,
                             Codable,
                             ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.init(rawValue: rawValue)
    }

    public init?(_ rawValue: String?) {
        guard let rawValue else {
            return nil
        }

        self.init(rawValue: rawValue)
    }

    public init(stringLiteral value: StringLiteralType) {
        self.init(rawValue: value)
    }
}

