import Foundation
import SwiftUI
import Utilities

public struct NavigationBarConfig: Equatable {
    public enum ItemPlacement: Hashable {
        case leading, center, trailing, background
    }

    public struct ItemContent: Equatable {
        let id = UUID()

        @IgnoreEquality
        var contentView: AnyView
    }

    public enum ItemState: Equatable {
        case hidden
        case content(ItemContent)

        init<T: View>(_ view: T) {
            self = .content(.init(contentView: AnyView(view)))
        }
    }

    var isHidden: Bool
    var style: NavigationBarStyle?
    var items: [ItemPlacement: ItemState]

    init(isHidden: Bool = false,
         style: NavigationBarStyle? = nil,
         items: [ItemPlacement: ItemState] = [:]) {
        self.isHidden = isHidden
        self.style = style
        self.items = items
    }

    mutating func merge(with next: Self) {
        isHidden = isHidden || next.isHidden
        style = style ?? next.style
        items.merge(next.items, uniquingKeysWith: { $1 })
    }
}

public extension NavigationBarConfig {
    struct Item {
        let placement: ItemPlacement
        let state: ItemState

        public init(placement: ItemPlacement,
                    state: ItemState) {
            self.placement = placement
            self.state = state
        }
    }

    init(isHidden: Bool, style: NavigationBarStyle? = nil, items: [Item]) {
        let keyAndValues = items.map {
            ($0.placement, $0.state)
        }

        self.init(isHidden: isHidden, style: style, items: .init(keyAndValues) {
            assertionFailure("Navigation bar item keys are not unique")
            return $1
        })
    }
}

public extension View {
    typealias NavigationItem = NavigationBarConfig.Item

    func navigationBarConfig(
        isHidden: Bool = false,
        style: NavigationBarStyle? = nil,
        @ArrayBuilder<NavigationItem>
        _ items: () -> [NavigationItem] = { [] }
    ) -> some View {
        background {
            Color.clear.preference(
                key: NavigationBarConfigKey.self,
                value: .init(isHidden: isHidden, style: style, items: items())
            )
        }
    }

    func navigationBarTitle(
        _ title: String,
        subtitle: String? = nil
    ) -> some View {
        navigationBarConfig {
            .title(title, subtitle: subtitle)
        }
    }

    func navigationBarDefaultHeight() -> some View {
        navigationBarConfig {
            .leading {
                NavigationBarCustomItem {
                    BackButton(action: {})
                        .navigationBarItem
                        .hidden()
                }
            }
        }
    }

    func onNavigationBarConfigChange(
        resetForParent: Bool,
        perform: @escaping (NavigationBarConfig) -> Void
    ) -> some View {
        onPreferenceChange(
            NavigationBarConfigKey.self,
            perform: perform
        )
        .transformPreference(NavigationBarConfigKey.self) { config in
            if resetForParent {
                config = NavigationBarConfigKey.defaultValue
            }
        }
    }
}

public extension NavigationBarConfig.Item {
    static func leading<T: View>(
        @NavigationBarLeadingItemsBuilder _ leading: () -> T
    ) -> Self {
        .init(placement: .leading,
              state: .init(leading()))
    }

    static func background<T: View>(
        @ViewBuilder _ background: () -> T
    ) -> Self {
        .init(placement: .background,
              state: .init(background()))
    }

    static var hideLeading: Self {
        .init(placement: .leading, state: .hidden)
    }

    static func trailing<T: View>(
        @NavigationBarTrailingItemsBuilder _ trailing: () -> T
    ) -> Self {
        .init(placement: .trailing,
              state: .init(trailing()))
    }

    static var hideTrailing: Self {
        .init(placement: .trailing, state: .hidden)
    }

    static func center<T: NavigationBarCenterItem>(
        @NavigationBarCenterItemsBuilder _ center: () -> T
    ) -> Self {
        .init(placement: .center,
              state: .init(center()))
    }

    static var hideCenter: Self {
        .init(placement: .center, state: .hidden)
    }

    static func title(
        _ title: String,
        subtitle: String? = nil
    ) -> Self {
        center {
            NavigationBarTitle(title: title,
                               subtitle: subtitle)
        }
    }
}

private struct NavigationBarConfigKey: PreferenceKey {
    static var defaultValue = NavigationBarConfig()

    static func reduce(
        value: inout NavigationBarConfig,
        nextValue: () -> NavigationBarConfig
    ) {
        value.merge(with: nextValue())
    }
}

