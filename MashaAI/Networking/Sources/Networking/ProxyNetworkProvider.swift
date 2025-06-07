import Foundation
import Utilities
import Logger

public final class ProxyNetworkProvider: NetworkProviding {

    private let wrapped: NetworkProvider

    public init(
        logger: AppLogging,
        plugins: [NetworkPlugin]
    ) {
        //TODO: - here we check if user has dev host in UserDefaults
        //TODO: - here we add plugins for dev/prod

        if AppConfiguration.current == .appStore {
            wrapped = NetworkProvider(
                env: .init(
                    scheme: "https",
                    env: .prod
                ),
                logger: logger
            )
        } else {
            wrapped = NetworkProvider(
                env: .init(
                    scheme: "https",
                    env: .prod
                ),
                plugins: plugins, 
                logger: logger
            )
        }
    }

    @discardableResult
    public func request<T>(_ request: T) async throws -> T.Response where T : ApiRequest {
        try await wrapped.request(request)
    }
}

public enum ServerEnvironmentSelector {
    case prod, dev(String)

    public var activeEnv: String {
        switch self {
        case .prod:          return ServerEnvironment.prod
        case .dev(let host): return host
        }
    }
}
