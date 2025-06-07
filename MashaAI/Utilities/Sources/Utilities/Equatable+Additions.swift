import Foundation

@propertyWrapper
public struct IgnoreEquality<Value>: Equatable {
    public var wrappedValue: Value

    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        true
    }
}
