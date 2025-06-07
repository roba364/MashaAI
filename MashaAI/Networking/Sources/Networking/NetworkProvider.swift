import Foundation
import Combine
import Utilities
import Logger

public protocol NetworkProviding {
    func request<T: ApiRequest>(_ request: T) async throws -> T.Response
}

public final class NetworkProvider: NetworkProviding {

    private typealias Output = (data: Data, response: URLResponse)

    private let session: URLSession
    private let decoder: JSONDecoder
    private let plugins: [NetworkPlugin]
    private let requestInterceptor: RequestInterceptor?
    private let logger: AppLogging
    private var env: ServerEnvironment

    public init(env: ServerEnvironment,
                configuration: URLSessionConfiguration = .default,
                decoder: JSONDecoder = .default,
                plugins: [NetworkPlugin] = [],
                requestInterceptor: RequestInterceptor? = nil,
                logger: AppLogging
    ) {
        self.env = env
        self.session = URLSession(configuration: configuration)
        self.decoder = decoder
        self.plugins = plugins
        self.requestInterceptor = requestInterceptor
        self.logger = logger
    }

    @discardableResult
    public func request<T: ApiRequest>(_ request: T) async throws -> T.Response {
        if let stubExecutor = request.stubExecutor {
            let response = try await stubExecutor.execute()
            return try handleStubResponse(response, for: request)
        }
        
        let urlRequest = try makeRequest(request)
        let adaptedRequest = try await adapt(urlRequest)
        let result = try await send(adaptedRequest)
        let decodedData = try decodeData(result.data, for: request)
        return decodedData
    }

    @discardableResult
    private func makeRequest<T: ApiRequest>(_ request: T) throws -> URLRequest {
        var urlComponents = URLComponents()

        urlComponents.scheme = env.scheme
        urlComponents.host = env.host.replacingOccurrences(of: "/", with: "")
        urlComponents.path = request.path.isEmpty ? "/" : request.path

        if !request.queryParameters.isEmpty {
            urlComponents.queryItems = request.queryParameters.map(URLQueryItem.init)
        }

        guard let url = urlComponents.url else {
            throw URLError(.badURL)
        }

        var urlRequest = URLRequest(url: url)

        urlRequest.httpMethod = request.method.rawValue
        
        let combinedHeaders = mandatoryHeaders.merging(request.headers) { $1 }
        urlRequest.addHeaders(combinedHeaders)

        return try request.encoder.encode(urlRequest, parameters: request.body)
    }

    @discardableResult
    private func adapt(_ request: URLRequest) async throws -> URLRequest {
        if let interceptor = requestInterceptor {
            return try await interceptor.adapt(request)
        } else {
            return request
        }
    }

    @discardableResult
    private func send(_ request: URLRequest) async throws -> Output {
        let (data, response) = try await session.data(for: request)
        plugins.forEach { $0.willSend(request) }
        plugins.forEach { $0.didReceive(data, from: request, with: response, nil) }
        return (data, response)
    }

    @discardableResult
    private func decodeData<T: ApiRequest>(_ data: Data, for request: T) throws -> T.Response {
        do {
            if T.Response.self is EmptyResponse.Type {
                return EmptyResponse() as! T.Response
            }

            let decodedData = try request.responseDecoder.decode(T.Response.self, from: data)
            return decodedData
        } catch let decodingError as DecodingError {
            logger.logDecodingError(decodingError)
            throw ApiError.decodingError(decodingError.localizedDescription)
        }
    }

    private func handleStubResponse<T: ApiRequest>(_ response: HttpResponse, for request: T) throws -> T.Response {
        guard (200...299).contains(response.statusCode) else {
            throw NetworkError.generic(message: "Stub error: Status code \(response.statusCode)")
        }
        
        if T.Response.self is EmptyResponse.Type {
            return EmptyResponse() as! T.Response
        }

        return try request.responseDecoder.decode(T.Response.self, from: response.data)
    }
}

private extension NetworkProvider {
    var mandatoryHeaders: [HttpHeaderKey: String] {
        [
            .xApiKey: "KtORZq5qQUz906Me8ZL9rt5gQG0umeQfA6EoacYSeTQAIvUMYJ"
        ]
    }
}

public enum ApiError: Error {
    case unauthorized
    case unknown(String, Int)
    case decodingError(String)
}

public protocol NetworkPlugin {
    func willSend(_ request: URLRequest)
    func didReceive(_ data: Data?, from request: URLRequest, with response: URLResponse?, _ error: Error?)
}

public enum HttpMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case put = "PUT"
    case head = "HEAD"
    case delete = "DELETE"
}

extension URLRequest {
    var method: HttpMethod? {
        guard let rawValue = httpMethod else { return nil }
        return HttpMethod(rawValue: rawValue)
    }
}

extension URLRequest {
    mutating func addHeaders(_ headers: [HttpHeaderKey: String]) {
        headers.forEach { key, value in
            addValue(value, forHTTPHeaderField: key.rawValue)
        }
    }
}

private extension Data {
    func normalized<T>(for data: T.Type) -> Data {
        if isEmpty {
            if "\(T.self)".hasPrefix("Array<"), let nullData = "[]".data(using: .utf8) {
                return nullData
            } else if let nullData = "{}".data(using: .utf8) {
                return nullData
            }
        }
        return self
    }
}

private extension AppLogging {
    func logDecodingError(_ error: DecodingError) {
        log(
            message: "Failed to decode: \(error.localizedDescription)",
            category: .error,
            level: .error,
            params: [
                "error": error.localizedDescription,
                "reason": error.failureReason ?? "",
                "desc": error.errorDescription ?? ""
            ],
            to: [.pulse],
            file: "",
            method: "",
            line: 0
        )
    }
}
