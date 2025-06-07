import Foundation

public struct HttpHeaderKey: Hashable, CustomStringConvertible {
    let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public var description: String {
        rawValue
    }
}

public extension HttpHeaderKey {
    static let contentType = HttpHeaderKey(rawValue: "Content-Type")
    static let accept = HttpHeaderKey(rawValue: "Accept")
    static let authorization = HttpHeaderKey(rawValue: "Authorization")
    static let userAgent = HttpHeaderKey(rawValue: "User-Agent")
    static let language = HttpHeaderKey(rawValue: "x-language")
    static let xApiKey = HttpHeaderKey(rawValue: "x-api-key")
}
