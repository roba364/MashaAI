import Foundation
import Combine
import SwiftUI

public protocol Broadcasting {}

public extension Broadcasting {
    func broadcast(on center: NotificationCenter = .default) {
        center.send(event: self as Self)
    }

    static func listen(on center: NotificationCenter = .default) -> AnyPublisher<Self, Never> {
        center.listenTo(Self.self)
    }

    static func listen(on center: NotificationCenter = .default,
                       _ perform: @escaping (Self) -> Void) -> AnyCancellable {
        center.listenTo(Self.self, perform: perform)
    }
}

public extension NotificationCenter {
    private func notificationName<T>(for type: T.Type) -> Notification.Name {
        .init(String(describing: type) + "_broadcast")
    }

    func listenTo<T>(_ type: T.Type = T.self) -> AnyPublisher<T, Never> {
        publisher(for: notificationName(for: type))
            .compactMap { $0.object as? T }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func listenTo<T>(_ type: T.Type = T.self, perform: @escaping (T) -> Void) -> AnyCancellable {
        listenTo(type)
            .sink(receiveValue: perform)
    }

    func send<T>(event: T) {
        post(name: notificationName(for: T.self), object: event)
    }

    class func listenTo<T>(_ type: T.Type = T.self, perform: @escaping (T) -> Void) -> AnyCancellable {
        `default`.listenTo(type, perform: perform)
    }

    class func listenTo<T>(_ type: T.Type = T.self) -> AnyPublisher<T, Never> {
        `default`.listenTo(type)
    }

    class func send<T>(event: T) {
        `default`.send(event: event)
    }
}

public extension View {
    func onBroadcast<T: Broadcasting>(_ type: T.Type = T.self, perform: @escaping (T) -> Void) -> some View {
        onReceive(type.listen(), perform: perform)
    }
}

public extension NotificationCenter {
    func listenToErrors() -> AnyPublisher<Error, Never> {
        publisher(for: notificationName(for: Error.self))
            .compactMap { $0.object as? Error }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func send(error: Error) {
        send(event: error)
    }
}

public extension Error {
    func broadcast(on center: NotificationCenter = .default) {
        center.send(error: self)
    }
}
