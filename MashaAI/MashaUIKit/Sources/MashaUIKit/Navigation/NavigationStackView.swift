import Foundation
import SwiftUI

public struct NavigationStackView<
    Coordinator: NavigationStackCoordinating,
    ScreenView: View,
    EmptyScreen: View
>: View {
    public typealias Screen = Coordinator.Screen

    @ObservedObject
    private var coordinator: Coordinator
    private let buildScreen: (Screen) -> ScreenView
    private let emptyContent: EmptyScreen

    private var stack: [Screen] { coordinator.stack }
    private var currentIndex: Int? { stack.indices.last }
    @State
    private var previousIndex: Int?

    public init(
        _ coordinator: Coordinator,
        @ViewBuilder
        buildScreen: @escaping (Screen) -> ScreenView,
        @ViewBuilder
        emptyContent: @escaping () -> EmptyScreen = { EmptyView() }
    ) {
        self.coordinator = coordinator
        self.buildScreen = buildScreen
        self.emptyContent = emptyContent()
    }

    public var body: some View {
        ZStack {
            if let currentIndex {
                screenView {
                    stackView(at: currentIndex)
                }
                .id(stack[currentIndex].id)
                .onAppear { previousIndex = currentIndex }
            } else {
                screenView {
                    emptyContent
                        .navigationBar()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func screenView<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        let dismissDuration = 0.3
        let appearDelay = previousIndex == nil ? 0 : dismissDuration

        content()
            .transition(.asymmetric(
                insertion: .opacity.animation(.cubic1(duration: 0.6).delay(appearDelay)),
                removal: .opacity.animation(.cubic3(duration: dismissDuration))
            ))
    }

    @ViewBuilder
    private func stackView(at index: Int) -> some View {
        let screen = stack[index]

        buildScreen(screen)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationBarConfig {
                if index > 0 {
                    .leading {
                        BackButton {
                            coordinator.onBack()
                        }
                        .navigationBarItem
                    }
                }
            }
            .navigationBar()
    }
}

public extension View {
    /// Adds navigation bar to receiver view.
    /// Does nothing if receiver view is a child of another navigation bar presenter.
    func navigationBar() -> some View {
        modifier(ConfigurableNavigationBarModifier())
    }
}

private struct ConfigurableNavigationBarModifier: ViewModifier {
    @Environment(\.navigationBarIsPresent)
    private var navigationBarIsPresent

    @State
    private var config = NavigationBarConfig()

    func body(content: Content) -> some View {
        content.navigationBarView {
            ConfigurableNavigationBar(config: config)
                .environment(
                    \.navigationBarStyle,
                     config.style ?? NavigationBarStyle(
                        typography: .H4.regular,
                        appearence: .light
                     )
                )
        }
        // stopping config from propagating to parent
        // if modified content is presenting navigation bar
        .onNavigationBarConfigChange(
            resetForParent: !navigationBarIsPresent
        ) { config in
            self.config = config
        }
    }
}

public extension View {

    func navigationBar<LeadingItems: View, CenterItem: NavigationBarCenterItem, TrailingItems: View, BackgroundItem: View>(
        isHidden: Bool = false,
        @NavigationBarLeadingItemsBuilder
        leading: @escaping () -> LeadingItems = { EmptyView() },
        @NavigationBarCenterItemsBuilder
        center: @escaping () -> CenterItem = { EmptyView() },
        @NavigationBarTrailingItemsBuilder
        trailing: @escaping () -> TrailingItems = { EmptyView() },
        @ViewBuilder
        background: @escaping () -> BackgroundItem = { EmptyView() }
    ) -> some View {
        navigationBarView {
            if !isHidden {
                NavigationBar(
                    leading: leading,
                    center: center,
                    trailing: trailing
                )
                .background(background())
                .transition(.opacity.animation(.default))
            }
        }
    }

    func navigationBarView<Content: View>(
        @ViewBuilder _ content: @escaping () -> Content
    ) -> some View {
        modifier(NavigationBarModifier(content))
    }

    /// Defines context for a new navigation bar to be added by child view hierarchy
    func navigationBarPresenter() -> some View {
        environment(\.navigationBarIsPresent, false)
    }
}

private struct NavigationBarIsPresentKey: EnvironmentKey {
    static var defaultValue = false
}

extension EnvironmentValues {
    var navigationBarIsPresent: Bool {
        get { self[NavigationBarIsPresentKey.self] }
        set { self[NavigationBarIsPresentKey.self] = newValue }
    }
}

private struct NavigationBarModifier<NavBar: View>: ViewModifier {

    @Environment(\.navigationBarIsPresent)
    private var navigationBarIsPresent

    private let navBar: () -> NavBar

    init(@ViewBuilder _ navBar: @escaping () -> NavBar) {
        self.navBar = navBar
    }

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .top, spacing: 0) {
                if !navigationBarIsPresent {
                    SafeAreaReader { safeAreaInsets in
                        navBar()
                            .safeAreaInset(edge: .top) {
                                Color.clear.frame(height: max(0, 5 - safeAreaInsets.top))
                            }
                    }
                }
            }
            .environment(\.navigationBarIsPresent, true)
    }
}

private struct ConfigurableNavigationBar: View {
    let config: NavigationBarConfig

    var body: some View {
        if !config.isHidden {
            NavigationBar(
                leading: {
                    NavigationBarCustomItem {
                        config.view(at: .leading)
                    }
                },
                center: {
                    NavigationBarCustomItem {
                        config.view(at: .center)
                    }
                },
                trailing: {
                    NavigationBarCustomItem {
                        config.view(at: .trailing)
                    }
                }
            )
            .background {
                config.view(at: .background)
            }
            .transition(.opacity.animation(.default))
        }
    }
}

extension NavigationBarConfig {
    @ViewBuilder
    func view(at placement: ItemPlacement) -> some View {
        switch items[placement] {
        case let .content(content):
            content.contentView
        case .none, .hidden:
            EmptyView()
        }
    }
}

public extension View {
    func insetConsideringSafeArea(
        edge: Edge,
        minInset: CGFloat,
        insetFromSafeArea: CGFloat = 0
    ) -> some View {
        SafeAreaReader { safeAreaInsets in
            SafeAreaReader(.keyboard) { keyboardInsets in
                let inset = max(minInset, safeAreaInsets[edge] - keyboardInsets[edge] + insetFromSafeArea)
                self.padding(
                    Edge.Set(edge),
                    inset
                )
                .ignoresSafeArea(.all.subtracting(.keyboard), edges: Edge.Set(edge))
            }
        }
    }

    /// Block based view safe area measurement
    func measureSafeArea(
        _ regions: SafeAreaRegions = .all,
        onChange: @escaping (EdgeInsets?) -> Void
    ) -> some View {
        overlay {
            GeometryReader {
                Color.clear.preference(
                    key: SafeAreaInsetsPreference<Self>.self,
                    value: $0.safeAreaInsets
                )
            }
            .ignoresSafeArea(.all.subtracting(regions))
        }
        .onPreferenceChange(
            SafeAreaInsetsPreference<Self>.self,
            perform: onChange
        )
    }
}

public struct SafeAreaReader<Content: View>: View {
    @State
    var safeAreaInsets: EdgeInsets?

    public var regions: SafeAreaRegions
    public let content: (EdgeInsets) -> Content

    public init(
        _ regions: SafeAreaRegions = .all,
        @ViewBuilder content: @escaping (EdgeInsets) -> Content
    ) {
        self.regions = regions
        self.content = content
    }

    public var body: some View {
        content(
            safeAreaInsets ?? .zero
        )
        .measureSafeArea(regions) { insets in
            safeAreaInsets = insets.map {
                EdgeInsets(
                    top: round($0.top),
                    leading: round($0.leading),
                    bottom: round($0.bottom),
                    trailing: round($0.trailing)
                )
            }
        }
    }
}

struct SafeAreaInsetsPreference<V>: PreferenceKey {
    static func reduce(value: inout EdgeInsets?, nextValue: () -> EdgeInsets?) {
        value = value ?? nextValue()
    }
}

public struct ViewBackport<Content: View> {

    public let content: Content

    public init(_ content: Content) {
        self.content = content
    }
}

public extension View {
    var backport: ViewBackport<Self> { .init(self) }
}

public extension ViewBackport {

    @ViewBuilder
    func safeAreaPadding(_ insets: EdgeInsets) -> some View {
        if #available(iOS 17, *) {
            content.safeAreaPadding(insets)
        } else {
            content
                .safeAreaInset(edge: .top, spacing: 0) { Color.clear.frame(height: insets.top) }
                .safeAreaInset(edge: .bottom, spacing: 0) { Color.clear.frame(height: insets.bottom) }
                .safeAreaInset(edge: .leading, spacing: 0) { Color.clear.frame(width: insets.leading) }
                .safeAreaInset(edge: .trailing, spacing: 0) { Color.clear.frame(width: insets.trailing) }
        }
    }
}
