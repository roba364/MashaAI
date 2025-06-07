import Foundation

public protocol RetryCondition {
    func shouldRetry(_ error: Error) -> Bool
}

public enum RetryTask {
    public struct Strategy {
        let maxAttempts: Int
        let backoff: RetryBackoffStrategy

        public static var `default`: Self {
            .init(maxAttempts: 10,
                  backoff: .fibonacci)
        }

        public init(maxAttempts: Int,
                    backoff: RetryBackoffStrategy) {
            self.maxAttempts = maxAttempts
            self.backoff = backoff
        }
    }

    public static func when<T>(
        _ condition: RetryCondition,
        strategy: Strategy = .default,
        action: () async throws -> T
    ) async rethrows -> T {
        var attempt = 0
        while true {
            do {
                return try await action()
            } catch {
                try Task.checkCancellation()
                attempt += 1

                guard attempt <= strategy.maxAttempts,
                      condition.shouldRetry(error) else {
                    throw error
                }

                try await Task.sleep(nanoseconds: UInt64(strategy.backoff.delay(for: attempt)))
            }
        }
    }
}

public struct BlockRetryCondition: RetryCondition {
    public let condition: (Error) -> Bool

    public init(condition: @escaping (Error) -> Bool) {
        self.condition = condition
    }

    public func shouldRetry(_ error: Error) -> Bool {
        condition(error)
    }
}

public extension RetryCondition where Self == BlockRetryCondition {
    static var anyError: RetryCondition {
        BlockRetryCondition { _ in return true}
    }

    static var never: RetryCondition {
        BlockRetryCondition { _ in return false }
    }
}

extension Array: RetryCondition where Element == RetryCondition {
    public func shouldRetry(_ error: Error) -> Bool {
        first { $0.shouldRetry(error) } != nil
    }
}
