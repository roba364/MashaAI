import Foundation

public protocol ApiRequest {
    associatedtype Response: Decodable = EmptyResponse

    var path: String { get }
    var method: HttpMethod { get }
    var queryParameters: [String: String] { get }
    var headers: [HttpHeaderKey: String] { get }
    var body: [String: Any]? { get }
    var encoder: ParameterEncoder { get }
    var responseDecoder: JSONDecoder { get }
    var stubExecutor: (any RequestExecutor)? { get }
}

public extension ApiRequest {
    var queryParameters: [String: String] { [:] }
    var headers: [HttpHeaderKey: String] { [:] }
    var body: [String: Any]? { nil }
    var encoder: ParameterEncoder { JSONParameterEncoder.default }
    var responseDecoder: JSONDecoder { JSONDecoder.default }
    var stubExecutor: (any RequestExecutor)? { nil }
}

public struct EmptyResponse: Decodable {}

public extension DateFormatter {
    static let iso8601FullTimezoned: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return formatter
    }()
}

public extension JSONDecoder {
    static var `default`: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(.iso8601FullTimezoned)
        return decoder
    }
}
