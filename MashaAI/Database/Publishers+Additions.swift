import Foundation
import Combine

extension Future {
    static func deferred(
        _ attemptToFulfill: @escaping (@escaping Promise) -> Void
    ) -> Deferred<Future<Output, Failure>> {
        Deferred { Future(attemptToFulfill) }
    }
}

extension Future where Failure == Error {

    static func deferred(
        _ asyncFunc: @escaping () async throws -> Output
    ) -> some Publisher<Output, Failure> {
        AnyPublisher.create { observer, lifetime in
            let task = Task {
                do {
                    let result = try await asyncFunc()
                    if !Task.isCancelled {
                        observer.sendNext(result)
                        observer.sendCompleted()
                    }
                } catch {
                    observer.sendError(error)
                }
            }
            lifetime.onCancel(task.cancel)
        }
    }
}

extension Future where Failure == Never {
    static func deferred(
        _ asyncFunc: @escaping () async -> Output
    ) -> some Publisher<Output, Failure> {
        AnyPublisher.create { observer, lifetime in
            let task = Task {
                let result = await asyncFunc()
                if !Task.isCancelled {
                    observer.sendNext(result)
                    observer.sendCompleted()
                }
            }
            lifetime.onCancel(task.cancel)
        }
    }
}

extension Just {
    static func deferred(
        _ value: @escaping () -> Output
    ) -> Deferred<Just<Output>> {
        Deferred { Just(value()) }
    }
}

extension AnyPublisher where Failure == Never {
    func asyncFirst() async -> Output? {
        await withCheckedContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = self.first().sink { value in
                continuation.resume(returning: value)
                cancellable?.cancel()
            }
        }
    }
}
