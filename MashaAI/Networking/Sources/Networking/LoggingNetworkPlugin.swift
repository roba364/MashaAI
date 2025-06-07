import Foundation
import os

public struct LoggingNetworkPlugin: NetworkPlugin {

    public struct LogComponents: OptionSet {
        public let rawValue: Int

        static let headers = LogComponents(rawValue: 1 << 0)
        static let body = LogComponents(rawValue: 1 << 1)

        public static let all: LogComponents = [.headers, .body]

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }

    let logComponents: LogComponents

    public init(logComponents: LogComponents) {
        self.logComponents = logComponents
    }

    public func willSend(_ request: URLRequest) {
        guard let url = request.url, let method = request.httpMethod else {
            return
        }

//        _ = formatMessage(with: "\(method) > \(url)",
//                                    headers: request.allHTTPHeaderFields,
//                                    body: request.httpBody)
    }

    public func didReceive(_ data: Data?, from request: URLRequest, with response: URLResponse?, _ error: Error?) {
        guard let httpResponse = response as? HTTPURLResponse,
              let url = response?.url?.absoluteString else {
            return
        }

//        _ = formatMessage(with: "< \(httpResponse.statusCode) \(url)",
//                                    headers: httpResponse.allHeaderFields,
//                                    body: data)
    }

    public func didFail(_ request: URLRequest, withError error: Error) {}

    public func formatMessage(with baseMessage: String,
                              headers: [AnyHashable: Any]?,
                              body: Data?) -> String {
        var components = [baseMessage]

        if logComponents.contains(.headers), let headers = headers {
            for header in headers {
                components.append("-H \"\(header.key): \(header.value)\"")
            }
        }

        if logComponents.contains(.body), let body = body {
            let httpBody = String(decoding: body, as: UTF8.self)
            components.append("-d \"\(httpBody)\"")
        }

        return components.joined(separator: " \\\n\t")
    }
}
