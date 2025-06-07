import Foundation

public protocol RequestExecutor {
    func execute() async throws -> HttpResponse
}

public struct HttpResponse {
    public let statusCode: Int
    public let headers: [HttpHeaderKey: String]
    public let data: Data
}

public struct StubExecutor: RequestExecutor {
    public var dataProvider: () throws -> Data = { Data() }
    public var delay: TimeInterval = 0.0
    public var statusCode: Int = 200
    public var error: Error?
    
    public init() {}
    
    public func execute() async throws -> HttpResponse {
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        
        if let error = error {
            throw error
        }
        
        let data = try dataProvider()
        return HttpResponse(
            statusCode: statusCode,
            headers: [:],
            data: data
        )
    }
}

extension StubExecutor {
    public func delay(_ delay: TimeInterval) -> Self {
        var executor = self
        executor.delay = delay
        return executor
    }
    
    public func error(_ error: Error) -> Self {
        var executor = self
        executor.error = error
        return executor
    }
    
    public func statusCode(_ code: Int) -> Self {
        var executor = self
        executor.statusCode = code
        return executor
    }
    
    public func data(_ data: Data) -> Self {
        var executor = self
        executor.dataProvider = { data }
        return executor
    }
    
    public func encoding<T: Encodable>(
        _ value: T,
        encoder: JSONEncoder = .init()
    ) -> Self {
        var executor = self
        executor.dataProvider = { try encoder.encode(value) }
        return executor
    }
} 
