import Foundation

public struct ServerEnvironment {
    public enum Env {
        case prod
        case dev(String)
    }

    let scheme: String
    let host: String

    public init(scheme: String, env: Env) {
        self.scheme = scheme

        switch env {
        case .prod:
            self.host = ServerEnvironment.prod
        case .dev(let host):
            self.host = host
        }
    }
}

extension ServerEnvironment {
    static let prod = "evo-service.com/"
    static let dev = "ec2-52-212-67-159.eu-west-1.compute.amazonaws.com/evolution/"
}
