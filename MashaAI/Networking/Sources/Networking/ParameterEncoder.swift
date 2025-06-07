import Foundation

public typealias Parameters = [String: Any]

public protocol ParameterEncoder {
    func encode(_ request: URLRequest, parameters: Parameters?) throws -> URLRequest
}

public struct URLEncoder: ParameterEncoder {

    public enum Destination {
        case methodDependent
        case queryString
        case httpBody

        func encodesParametersInURL(for method: HttpMethod) -> Bool {
            switch self {
            case .methodDependent: return [.get, .head, .delete].contains(method)
            case .queryString: return true
            case .httpBody: return false
            }
        }
    }

    enum ArrayEncoding {
        case brackets
        case noBrackets

        func encode(key: String) -> String {
            switch self {
            case .brackets: return "\(key)[]"
            case .noBrackets: return key
            }
        }
    }

    enum BoolEncoding {
        case numeric
        case literal

        func encode(value: Bool) -> String {
            switch self {
            case .numeric: return value ? "1" : "0"
            case .literal: return value ? "true" : "false"
            }
        }
    }

    public static var `default`: URLEncoder { return URLEncoder() }

    public let destination: Destination
    private let arrayEncoding: ArrayEncoding
    private let boolEncoding: BoolEncoding

    init(destination: Destination = .methodDependent,
         arrayEncoding: ArrayEncoding = .brackets,
         boolEncoding: BoolEncoding = .numeric) {
        self.destination = destination
        self.arrayEncoding = arrayEncoding
        self.boolEncoding = boolEncoding
    }

    public func encode(_ request: URLRequest, parameters: Parameters?) throws -> URLRequest {
        var urlRequest = request

        guard let parameters = parameters else { return urlRequest }

        if let method = urlRequest.method, destination.encodesParametersInURL(for: method) {
            guard let url = urlRequest.url else { throw NetworkError.malformedUrl }

            if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false), !parameters.isEmpty {
                let percentEncodedQuery = (urlComponents.percentEncodedQuery.map { $0 + "&" } ?? "") + query(parameters)
                urlComponents.percentEncodedQuery = percentEncodedQuery
                urlRequest.url = urlComponents.url
            }
        } else {
            if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
                urlRequest.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
            }

            urlRequest.httpBody = Data(query(parameters).utf8)
        }

        return urlRequest
    }

    private func queryComponents(fromKey key: String, value: Any) -> [(String, String)] {
        var components: [(String, String)] = []

        if let dictionary = value as? [String: Any] {
            for (nestedKey, value) in dictionary {
                components += queryComponents(fromKey: "\(key)[\(nestedKey)]", value: value)
            }
        } else if let array = value as? [Any] {
            for value in array {
                components += queryComponents(fromKey: arrayEncoding.encode(key: key), value: value)
            }
        } else if let value = value as? NSNumber {
            if value.isBool {
                components.append((escape(key), escape(boolEncoding.encode(value: value.boolValue))))
            } else {
                components.append((escape(key), escape("\(value)")))
            }
        } else if let bool = value as? Bool {
            components.append((escape(key), escape(boolEncoding.encode(value: bool))))
        } else {
            components.append((escape(key), escape("\(value)")))
        }

        return components
    }

    private func escape(_ string: String) -> String {
        return string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? string
    }

    private func query(_ parameters: [String: Any]) -> String {
        var components: [(String, String)] = []

        for key in parameters.keys.sorted(by: <) {
            if let value = parameters[key] {
                components += queryComponents(fromKey: key, value: value)
            }
        }

        return components.map { "\($0)=\($1)" }.joined(separator: "&")
    }
}

public struct JSONParameterEncoder: ParameterEncoder {

    public static var `default`: JSONParameterEncoder { return JSONParameterEncoder() }

    private let options: JSONSerialization.WritingOptions

    public init(options: JSONSerialization.WritingOptions = []) {
        self.options = options
    }

    public func encode(_ request: URLRequest, parameters: Parameters?) throws -> URLRequest {
        var urlRequest = request

        guard let parameters = parameters else { return urlRequest }

        let data = try JSONSerialization.data(withJSONObject: parameters, options: options)

        if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        urlRequest.httpBody = data

        return urlRequest
    }
}

public struct ArrayEncoding: ParameterEncoder {

    public static var `default`: ArrayEncoding { return ArrayEncoding() }
    static let key = "array_encoding_key"

    private let options: JSONSerialization.WritingOptions

    init(options: JSONSerialization.WritingOptions = []) {
        self.options = options
    }

    public func encode(_ request: URLRequest, parameters: Parameters?) throws -> URLRequest {
        var urlRequest = request

        guard let parameters = parameters, let array = parameters[ArrayEncoding.key] else { return urlRequest }

        let data = try JSONSerialization.data(withJSONObject: array, options: options)

        if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        urlRequest.httpBody = data

        return urlRequest
    }
}

fileprivate extension NSNumber {
    var isBool: Bool { return CFBooleanGetTypeID() == CFGetTypeID(self) }
}

extension Array {
    func asParameters() -> Parameters {
        return [ArrayEncoding.key: self]
    }
}

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
