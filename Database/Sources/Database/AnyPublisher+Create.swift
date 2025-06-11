import Foundation
import Combine

extension Publishers {
    struct SideEffect<Output, Failure: Error>: Publisher {
        typealias StartHandler = (Observer, Lifetime) -> Void

        struct Observer {
            let sendNext: (Output) -> Void
            let sendError: (Failure) -> Void
            let sendCompleted: () -> Void
        }

        class Lifetime {
            private let lock = NSLock()
            private var _isCancelled: Bool = false
            private var _onCancel: (() -> Void)?

            var isCancelled: Bool {  sync { _isCancelled } }

            func onCancel(_ block: @escaping () -> Void) {
                sync { _onCancel = block }
            }

            func cancel() {
                let cancelBlock: (() -> Void)? = sync {
                    _isCancelled = true
                    return _onCancel
                }
                cancelBlock?()
            }

            private func sync<T>(_ block: () -> T) -> T {
                lock.lock()
                defer { lock.unlock() }
                return block()
            }
        }

        private class SideEffectSubscription<S: Subscriber>: Combine.Subscription where S.Input == Output, S.Failure == Failure {
            private var subscriber: S?
            private var startHandler: StartHandler?
            private let lifetime = Lifetime()

            init(subscriber: S, startHandler: @escaping StartHandler) {
                self.subscriber = subscriber
                self.startHandler = startHandler
            }

            func start() {
                guard let subscriber = subscriber else { return }
                let observer = Observer(
                    sendNext: subscriber.receiveValue,
                    sendError: subscriber.receiveError,
                    sendCompleted: subscriber.receiveCompletion
                )
                startHandler?(observer, lifetime)
            }

            func request(_ demand: Subscribers.Demand) {}

            func cancel() {
                lifetime.cancel()
                subscriber = nil
                startHandler = nil
            }
        }

        private let startHandler: StartHandler

        init(startHandler: @escaping StartHandler) {
            self.startHandler = startHandler
        }

        func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
            let subscription = SideEffectSubscription(subscriber: subscriber,
                                                      startHandler: startHandler)
            subscriber.receive(subscription: subscription)
            subscription.start()
        }
    }
}

extension AnyPublisher {
    typealias Observer = Publishers.SideEffect<Output, Failure>.Observer
    typealias Lifetime = Publishers.SideEffect<Output, Failure>.Lifetime

    static func create(_ startHandler: @escaping (Observer, Lifetime) -> Void) -> AnyPublisher<Output, Failure> {
        return Publishers.SideEffect(startHandler: startHandler).eraseToAnyPublisher()
    }
}

extension Publisher {
    func ignoreFailure(completeImmediately: Bool = true) -> AnyPublisher<Output, Never> {
        `catch` { _ in Empty(completeImmediately: completeImmediately) }
            .eraseToAnyPublisher()
    }

    func ignoreFailure<NewFailure: Error>(
        setFailureType newFailureType: NewFailure.Type,
        completeImmediately: Bool = true) -> AnyPublisher<Output, NewFailure> {
            ignoreFailure(completeImmediately: completeImmediately)
                .setFailureType(to: newFailureType)
                .eraseToAnyPublisher()
        }

    func asyncMap<T>(_ transform: @escaping (Output) async throws -> T) -> AnyPublisher<T, Error> {
        mapError { $0 as Error }
            .map { value -> Future<T, Error> in
                Future { promise in
                    Task {
                        do {
                            let output = try await transform(value)
                            promise(.success(output))
                        } catch {
                            promise(.failure(error))
                        }
                    }
                }
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }
}


extension Subject {
    func sendError(_ error: Failure) {
        send(completion: .failure(error))
    }

    func sendCompleted() {
        send(completion: .finished)
    }
}

extension Subscriber {
    func receiveValue(_ value: Input) {
        _ = receive(value)
    }

    func receiveError(_ error: Failure) {
        receive(completion: .failure(error))
    }

    func receiveCompletion() {
        receive(completion: .finished)
    }
}
