import Foundation
import SwiftUI

public struct NavigationBarStyle: Equatable {
    public static func == (lhs: NavigationBarStyle, rhs: NavigationBarStyle) -> Bool {
        lhs.appearence == rhs.appearence
    }

    public enum AppearenceStyle {
        case dark, light
    }

    let typography: UIFont.Typography
    let appearence: AppearenceStyle

    public init(
        typography: UIFont.Typography = .M1.bold,
        appearence: AppearenceStyle = .light
    ) {
        self.typography = typography
        self.appearence = appearence
    }
}

private struct NavigationBarStyleKey: EnvironmentKey {
    public static var defaultValue: NavigationBarStyle = .init(
        typography: .M1.bold,
        appearence: .light
    )
}

public extension EnvironmentValues {
    var navigationBarStyle: NavigationBarStyle {
        get { self[NavigationBarStyleKey.self] }
        set { self[NavigationBarStyleKey.self] = newValue }
    }
}
