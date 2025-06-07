import Foundation

public protocol RequestInterceptor {
    func adapt(_ request: URLRequest) async throws -> URLRequest
}
