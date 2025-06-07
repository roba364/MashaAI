import Foundation
import SwiftUI

public extension EdgeInsets {

    static var zero: EdgeInsets { .init() }

    init(_ edges: Edge.Set, _ inset: CGFloat) {
        self = Self.insets(for: edges, value: inset)
    }

    func and(_ edges: Edge.Set, _ inset: CGFloat) -> Self {
        Self.insets(for: edges, value: inset, initial: self)
    }

    func modifying(_ edge: Edge, update: (inout CGFloat) -> Void) -> Self {
        var insets = self
        update(&insets[edge])
        return insets
    }

    private static func insets(
        for edges: Edge.Set,
        value: CGFloat,
        initial: EdgeInsets = .init()
    ) -> Self {
        var insets = initial
        for edge in Edge.allCases {
            guard edges.contains(.init(edge)) else { continue }
            switch edge {
            case .bottom: insets.bottom = value
            case .leading: insets.leading = value
            case .trailing: insets.trailing = value
            case .top: insets.top = value
            }
        }
        return insets
    }
}

public extension EdgeInsets {
    subscript(_ edge: Edge) -> CGFloat {
        get {
            switch edge {
            case .top:
                return top
            case .leading:
                return leading
            case .bottom:
                return bottom
            case .trailing:
                return trailing
            }
        }
        set {
            switch edge {
            case .top:
                top = newValue
            case .leading:
                leading = newValue
            case .bottom:
                bottom = newValue
            case .trailing:
                trailing = newValue
            }
        }
    }
}

public extension EdgeInsets {

    init(_ insets: UIEdgeInsets) {
        self.init(
            top: insets.top,
            leading: insets.left,
            bottom: insets.bottom,
            trailing: insets.right
        )
    }
}

public extension UIEdgeInsets {

    init(_ insets: EdgeInsets) {
        self.init(
            top: insets.top,
            left: insets.leading,
            bottom: insets.bottom,
            right: insets.trailing
        )
    }
}
