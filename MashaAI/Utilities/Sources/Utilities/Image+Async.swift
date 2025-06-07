import Foundation
import SwiftUI

public extension Image {
//    static func asyncView<ModifiedImage: View, Placeholder: View>(
//        image: AsyncImageModel?,
//        @ViewBuilder imageModifier: @escaping (Image) -> ModifiedImage,
//        @ViewBuilder placeholder: @escaping () -> Placeholder
//    ) -> some View {
//        AsyncValueView(
//            value: image,
//            content: { imageModifier(Image(uiImage: $0)) },
//            error: { _ in placeholder() },
//            placeholder: placeholder
//        )
//    }

//    static func asyncResizableView<Placeholder: View>(
//        image: AsyncImageModel?,
//        @ViewBuilder placeholder: @escaping () -> Placeholder
//    ) -> some View {
//        asyncView(image: image,
//                  imageModifier: { $0.resizable() },
//                  placeholder: placeholder)
//    }
}

public typealias PlatformImage = UIImage
public typealias AsyncImageModel = AsyncValue<PlatformImage>
public typealias AsyncFile = AsyncValue<URL>

public protocol AsyncValueProviding<Value>: Equatable {
    associatedtype Value = Self
    var value: Value { get async throws }

    @MainActor
    var syncValue: Value? { get throws }
}

public struct AsyncValue<T>: Equatable, AsyncValueProviding {

    private let id: Any
    private let _value: () async throws -> T
    private let _syncValue: (@MainActor () throws -> T?)?

    private let _isEqual: (AsyncValue<T>) -> Bool

    public init<Identifier: Equatable>(
        id: Identifier,
        value: @escaping () async throws -> Value,
        syncValue: (@MainActor () throws -> Value?)? = nil
    ) {
        self.id = id
        self._value = value
        self._syncValue = syncValue
        self._isEqual = { other in
            id == (other.id as? Identifier)
        }
    }

    public init<P: AsyncValueProviding>(_ provider: P) where P.Value == T {
        self.init(id: provider) {
            try await provider.value
        } syncValue: {
            try provider.syncValue
        }
    }

    public init(_ value: T) where T: Equatable {
        self.init(id: value) {
            value
        } syncValue: {
            value
        }
    }

    public var value: T {
        get async throws {
            try await _value()
        }
    }

    public var syncValue: T? {
        get throws {
            try _syncValue?()
        }
    }

    public static func == (lhs: AsyncValue<T>,
                           rhs: AsyncValue<T>) -> Bool {
        lhs._isEqual(rhs)
    }
}

extension AsyncValueProviding {
    public func toAsyncValue() -> AsyncValue<Value> {
        .init(self)
    }
}

extension AsyncValueProviding {

    public func map<T>(_ transform: @escaping (Value) throws -> T) -> AsyncValue<T> {
        AsyncValue(id: self) {
            try await transform(value)
        } syncValue: {
            try? syncValue.map(transform)
        }
    }

    public func map<T>(_ transform: @escaping (Value) async throws -> T) -> AsyncValue<T> {
        AsyncValue(id: self) {
            try await transform(value)
        }
    }

    public func flatMap<T>(_ transform: @escaping (Value) throws -> AsyncValue<T>) -> AsyncValue<T> {
        AsyncValue(id: self) {
            try await transform(value).value
        } syncValue: {
            try syncValue.map(transform)?.syncValue
        }
    }
}

public extension AsyncValueProviding where Value == Self {
    var value: Value { self }
    var syncValue: Value? { self }
}

extension PlatformImage: AsyncValueProviding {}
extension URL: AsyncValueProviding {}
