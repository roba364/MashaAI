import Foundation

public protocol RetryBackoffStrategy {
    func delay(for attemptNumber: Int) -> TimeInterval
}

public extension RetryBackoffStrategy where Self == FibonacciBackoff {
    static var fibonacci: RetryBackoffStrategy {
        FibonacciBackoff()
    }
}

public extension RetryBackoffStrategy where Self == ExponentialBackoff {
    static var exponent: RetryBackoffStrategy {
        ExponentialBackoff()
    }
}

public class FibonacciBackoff: RetryBackoffStrategy {

    public func delay(for attemptNumber: Int) -> TimeInterval {
        TimeInterval(fibbonachi(number: attemptNumber))
    }

    private func fibbonachi(number: Int) -> Int {
        guard number > 0 else { return 0 }

        var first = 0
        var last = 1

        for _ in 1...number {
            last += first
            first = last - first
        }

        return last
    }
}

public class ExponentialBackoff: RetryBackoffStrategy {
    public func delay(for attemptNumber: Int) -> TimeInterval {
        pow(2, TimeInterval(attemptNumber))
    }
}

extension TimeInterval: RetryBackoffStrategy {
    public func delay(for attemptNumber: Int) -> TimeInterval {
        attemptNumber > 0 ? self : 0
    }
}

extension Array: RetryBackoffStrategy where Element == TimeInterval {
    public func delay(for attemptNumber: Int) -> TimeInterval {
        guard attemptNumber > 0 else { return 0 }

        return self[attemptNumber - 1]
    }
}
