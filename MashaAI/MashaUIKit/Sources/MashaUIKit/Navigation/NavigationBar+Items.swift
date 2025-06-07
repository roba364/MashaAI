import SwiftUI

public protocol NavigationBarItem: View {}
public protocol NavigationBarLeadingItem: NavigationBarItem {}
public protocol NavigationBarCenterItem: NavigationBarItem {}
public protocol NavigationBarTrailingItem: NavigationBarItem {}

extension EmptyView: NavigationBarLeadingItem, NavigationBarCenterItem, NavigationBarTrailingItem {}
extension Group: NavigationBarItem,
                 NavigationBarLeadingItem,
                 NavigationBarCenterItem,
                 NavigationBarTrailingItem where Content: View {}

public extension BackButton {
    private struct NavigationBarItem: NavigationBarLeadingItem {
        let button: BackButton
        var body: some View {
            button.padding(.vertical, 15)
        }
    }

    var navigationBarItem: some NavigationBarLeadingItem {
        NavigationBarItem(button: self)
    }
}

public extension CloseButton {
    private struct NavigationBarItem: NavigationBarLeadingItem, NavigationBarTrailingItem {
        let button: CloseButton

        var body: some View {
            button.padding(.top, 20)
        }
    }

    var navigationBarItem: some (NavigationBarLeadingItem & NavigationBarTrailingItem) {
        NavigationBarItem(button: self)
    }
}

public struct NavigationBarCustomItem<Content: View>:
    NavigationBarLeadingItem,
    NavigationBarTrailingItem,
    NavigationBarCenterItem {

    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View { content }
}

// MARK: - Item builders

@resultBuilder
public struct NavigationBarLeadingItemsBuilder {
    public static func buildPartialBlock<Item: NavigationBarLeadingItem>(first content: Item) -> Item {
        content
    }

    public static func buildPartialBlock<C0: View, C1: NavigationBarLeadingItem>(accumulated: C0, next: C1) -> TupleView<(C0, C1)> {
        TupleView((accumulated, next))
    }

    public static func buildEither<C0: NavigationBarLeadingItem, С1: NavigationBarLeadingItem>(first component: C0) -> some View {
        NavigationBarCustomItem { component }
    }

    public static func buildEither<C0: NavigationBarLeadingItem, С1: NavigationBarLeadingItem>(second component: С1) -> some View {
        NavigationBarCustomItem { component }
    }

    public static func buildOptional<C: NavigationBarLeadingItem>(_ component: C?) -> some View {
        NavigationBarCustomItem {
            if let component {
                component
            } else {
                EmptyView()
            }
        }
    }
}

@resultBuilder
public struct NavigationBarCenterItemsBuilder {
    public static func buildPartialBlock<Item: NavigationBarCenterItem>(first content: Item) -> Item {
        content
    }

    public static func buildPartialBlock<C0: View, C1: NavigationBarCenterItem>(accumulated: C0, next: C1) -> TupleView<(C0, C1)> {
        TupleView((accumulated, next))
    }
}

@resultBuilder
public struct NavigationBarTrailingItemsBuilder {
    public static func buildPartialBlock<Item: NavigationBarTrailingItem>(first content: Item) -> Item {
        content
    }

    public static func buildPartialBlock<C0: View, C1: NavigationBarTrailingItem>(accumulated: C0, next: C1) -> TupleView<(C0, C1)> {
        TupleView((accumulated, next))
    }
}

public extension NavigationBar {
    typealias LeadingItemsBuilder = NavigationBarLeadingItemsBuilder
    typealias CenterItemsBuilder = NavigationBarCenterItemsBuilder
    typealias TrailingItemsBuilder = NavigationBarTrailingItemsBuilder
}
