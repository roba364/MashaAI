import SwiftUI

public extension View {
    func typography(_ t: UIFont.Typography) -> some View {
        modifier(TypographyViewModifier(typography: t))
    }
}

struct TypographyKey: EnvironmentKey {
    static let defaultValue: UIFont.Typography = .textS
}

extension EnvironmentValues {
    var typography: TypographyKey.Value {
        get { return self[TypographyKey.self] }
        set { self[TypographyKey.self] = newValue }
    }
}

private struct TypographyViewModifier: ViewModifier {
    let typography: UIFont.Typography

    func body(content: Content) -> some View {
        content
            .font(Font(typography.font))
            .frame(minHeight: typography.lineHeight)
            .lineSpacing(typography.lineSpacing)
            .environment(\.typography, typography)
    }
}

extension UIFont {
    /**
     Evo font

     - 200 – Ultra Light.
     - 300 – Thin.
     - 400 – Light.
     - 500 – Regular.
     - 600 – Medium.
     - 700 – Bold.
     - 800 – Black.
     */
    static func proText(size: CGFloat, weight: UIFont.Weight = .light) -> UIFont {
        return UIFont.systemFont(ofSize: size, weight: weight)
    }

    static func proDisplay(size: CGFloat, weight: UIFont.Weight = .light) -> UIFont {
        let name: String = {
            switch weight {
            case .bold: return "SFProDisplay-Bold"
            case .regular: return "SFProDisplay-Regular"
            case .light: return "SF-Pro-Display-Light"
            case .medium: return "SF-Pro-Display-Medium"
            default: return "SF-Pro-Display-Regular"
            }
        }()

        return .init(name: name, size: size) ?? .proText(size: size, weight: weight)
    }
}

public extension UIFont {
    /// Custom Evo app typography. Should be added via extensions
    ///
    /// Example:
    /// ```swift
    ///     extension UIFont.Typography {
    ///         static let h1 = Self.proText(size: 76, weight: .black, lineHeight: 76)
    ///     }
    /// ```
    ///
    /// Usage:
    /// ```swift
    ///     someView
    ///         .typography(.h1)
    /// ```
    struct Typography {
        public let font: UIFont
        public let lineHeight: CGFloat

        public var lineSpacing: CGFloat {
            lineHeight - font.lineHeight
        }
    }
}

extension UIFont.Typography {
    /**
     Evo font typography
     - Parameters:
     - size: font size
     - weight: font weight:
     - 200 – Ultra Light.
     - 300 – Thin.
     - 400 – Light.
     - 500 – Regular.
     - 600 – Medium.
     - 700 – Bold.
     - 800 – Black.
     - lineHeight: typography line height
     */

    static func proText(
        size: CGFloat,
        weight: UIFont.Weight = .light, // 400
        lineHeight: CGFloat
    ) -> Self {
        .init(
            font: .proText(size: size, weight: weight),
            lineHeight: lineHeight
        )
    }

    static func proDisplay(
        size: CGFloat,
        weight: UIFont.Weight = .light, // 400
        lineHeight: CGFloat
    ) -> Self {
        .init(
            font: .proDisplay(size: size, weight: weight),
            lineHeight: lineHeight
        )
    }
}

public extension Font {
    static let font = UIFont.Typography.self
}

public extension UIFont.Typography {
    struct T1 {
        public static let regular = UIFont.Typography.proDisplay(size: 16, weight: .regular, lineHeight: 24)
        public static let regularSubtitle = UIFont.Typography.proDisplay(size: 14, lineHeight: 26)
        public static let bold = UIFont.Typography.proText(size: 16, weight: .bold, lineHeight: 24)
        public static let subRegular = UIFont.Typography.proText(size: 12, weight: .regular, lineHeight: 16)
    }

    struct T2 {
        public static let regular = UIFont.Typography.proText(size: 14, weight: .regular, lineHeight: 20)
        public static let sub2 = UIFont.Typography.proText(size: 10, weight: .regular, lineHeight: 12)
        public static let bold = UIFont.Typography.proText(size: 14, weight: .bold, lineHeight: 20)
        public static let sub2Bold = UIFont.Typography.proText(size: 10, weight: .bold, lineHeight: 12)
    }

    struct H1 {
        public static let regular = UIFont.Typography.proText(size: 24, weight: .medium, lineHeight: 32)
        public static let bold = UIFont.Typography.proText(size: 24, weight: .bold, lineHeight: 32)
        public static let paywall = UIFont.Typography.proText(size: 28, weight: .regular, lineHeight: 32)
    }

    struct H2 {
        public static let light = UIFont.Typography.proDisplay(size: 20, weight: .light, lineHeight: 26)
        public static let regular = UIFont.Typography.proDisplay(size: 20, weight: .medium, lineHeight: 26)
        public static let bold = UIFont.Typography.proDisplay(size: 20, weight: .bold, lineHeight: 26)
        public static let superBold = UIFont.Typography.proDisplay(size: 22, weight: .bold, lineHeight: 26)
        public static let proText = UIFont.Typography.proDisplay(size: 20, weight: .bold, lineHeight: 32)
    }

    struct H3 {
        public static let regular = UIFont.Typography.proDisplay(size: 20, weight: .medium, lineHeight: 28)
        public static let bold = UIFont.Typography.proDisplay(size: 20, weight: .bold, lineHeight: 28)
    }

    struct H4 {
        public static let regular = UIFont.Typography.proDisplay(size: 18, weight: .medium, lineHeight: 26)
        public static let bold = UIFont.Typography.proDisplay(size: 18, weight: .bold, lineHeight: 26)
    }

    static let superbold = Self.proText(size: 54, weight: .bold, lineHeight: 16)
    static let dnaProBold = Self.proText(size: 8, weight: .bold, lineHeight: 12)
    static let text = Self.proDisplay(size: 16, weight: .light, lineHeight: 24)
    static let textS = Self.proText(size: 14, weight: .light, lineHeight: 20)
    static let textSb = Self.proText(size: 14, weight: .bold, lineHeight: 20)
    static let paywallB = Self.proText(size: 14, weight: .bold, lineHeight: 18)
    static let cardThumbTitle = Self.proDisplay(size: 14, weight: .regular, lineHeight: 18)
    static let randomText = Self.proText(size: 14, weight: .regular, lineHeight: 16)
    static let textSub = Self.proText(size: 12, weight: .light, lineHeight: 16)
    static let textProBold = Self.proDisplay(size: 12, weight: .bold, lineHeight: 18)
    static let textPrimary = Self.proText(size: 18, weight: .light, lineHeight: 20)
    static let textPrimaryRegular = Self.proDisplay(size: 18, weight: .bold, lineHeight: 20)
    static let headline = Self.proText(size: 17, weight: .regular, lineHeight: 22)
    static let footnote = Self.proText(size: 13, weight: .regular, lineHeight: 18)
    static let talent = Self.proDisplay(size: 22, weight: .regular, lineHeight: 32)
    static let shareBtn = Self.proText(size: 18, weight: .medium, lineHeight: 20)
    static let cardTitle = Self.proDisplay(size: 14, weight: .bold, lineHeight: 18)
    static let cardSubtitle = Self.proText(size: 24, weight: .bold, lineHeight: 32)
    static let dailyAffirmation = Self.proDisplay(size: 20, weight: .bold, lineHeight: 31)
    static let titleTextProBold = Self.proText(size: 18, weight: .bold, lineHeight: 24)
    static let dailyAffirmationTitle = Self.proText(size: 14, weight: .light, lineHeight: 14)
    static let dnaProfileTitle = Self.proText(size: 16, weight: .bold, lineHeight: 20)
    static let timer = Self.proText(size: 40, weight: .bold, lineHeight: 41)
    static let sectionTitle = Self.proDisplay(size: 16, weight: .medium, lineHeight: 18)
    static let profileSummaryButton = Self.proDisplay(size: 16, weight: .semibold, lineHeight: 26)
}

extension Font {
    static func proText(size: CGFloat, weight: UIFont.Weight = .regular) -> Font {
        .init(UIFont.proText(size: size, weight: weight))
    }

    static func proDisplay(size: CGFloat, weight: UIFont.Weight = .regular) -> Font {
        .init(UIFont.proDisplay(size: size, weight: weight))
    }
}

public extension NSAttributedString {
    func typography(_ t: UIFont.Typography) -> Self {
        let attributedString = NSMutableAttributedString(attributedString: self)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = t.lineSpacing
        let attributes: [NSAttributedString.Key: Any] = [
            .font: t.font,
            .paragraphStyle: paragraphStyle,
        ]
        attributedString.addAttributes(attributes,
                                       range: NSRange(location: 0,
                                                      length: string.utf16.count))
        return .init(attributedString: attributedString)
    }
}

extension String {
    func typography(_ t: UIFont.Typography) -> NSAttributedString {
        NSAttributedString(string: self).typography(t)
    }
}

