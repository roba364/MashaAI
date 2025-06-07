import Foundation
import SwiftUI

public extension Comparable {

    func clamped(_ limits: PartialRangeThrough<Self>) -> Self {
        min(limits.upperBound, self)
    }

    func clamped(_ limits: PartialRangeFrom<Self>) -> Self {
        max(limits.lowerBound, self)
    }

    func clamped(_ limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}

@propertyWrapper
public struct Clamped<Value: Comparable & Sendable>: Sendable {

    var value: Value
    let range: ClosedRange<Value>

    public init(wrappedValue: Value? = nil, _ range: ClosedRange<Value>) {
        let value = wrappedValue ?? range.lowerBound

        self.range = range
        self.value = value
    }

    public var wrappedValue: Value {
        get { value }
        set { value = newValue.clamped(range) }
    }
}
