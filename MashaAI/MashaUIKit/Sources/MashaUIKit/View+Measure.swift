import Foundation
import SwiftUI

private struct MeasuredGeometryPreference<V, Value: Equatable>: PreferenceKey {
    static func reduce(value: inout Value?, nextValue: () -> Value?) {
        value = value ?? nextValue()
    }
}

public extension View {
    func measure<Value: Equatable>(
        value: @escaping (GeometryProxy) -> Value?,
        assignTo boundValue: Binding<Value?>? = nil,
        onChange: ((Value?) -> Void)? = nil
    ) -> some View {
        overlay(GeometryReader { geometry in
            Color.clear.preference(
                key: MeasuredGeometryPreference<Self, Value>.self,
                value: value(geometry)
            )
        })
        .onPreferenceChange(MeasuredGeometryPreference<Self, Value>.self) { newValue in
            boundValue?.wrappedValue = newValue
            onChange?(newValue)
        }
    }

    /// Block based view size measurement
    func measure<Value: Equatable>(
        _ keyPath: KeyPath<GeometryProxy, Value> = \.size,
        assignTo value: Binding<Value?>? = nil,
        onChange: ((Value?) -> Void)? = nil
    ) -> some View {
        measure(
            value: { $0[keyPath: keyPath] },
            assignTo: value,
            onChange: onChange
        )
    }

    func overlaySize<T: View>(
        @ViewBuilder _ transform: @escaping (CGSize) -> T
    ) -> some View {
        overlay(GeometryReader { geometry in
            Color.clear.preference(
                key: MeasuredGeometryPreference<Self, CGSize>.self,
                value: geometry.size
            )
        })
        .overlayPreferenceValue(MeasuredGeometryPreference<Self, CGSize>.self) {
            transform($0 ?? .zero)
        }
    }

    func background<T: View, Value: Equatable>(
        geometryValue: @escaping (GeometryProxy) -> Value,
        @ViewBuilder _ transform: @escaping (Value?) -> T
    ) -> some View {
        overlay(GeometryReader { geometry in
            Color.clear.preference(
                key: MeasuredGeometryPreference<Self, Value>.self,
                value: geometryValue(geometry)
            )
        })
        .backgroundPreferenceValue(MeasuredGeometryPreference<Self, Value>.self) {
            transform($0)
        }
    }

    func backgroundSize<T: View>(
        @ViewBuilder _ transform: @escaping (CGSize) -> T
    ) -> some View {
        background(geometryValue: { $0.size }) {
            transform($0 ?? .zero)
        }
    }
}
