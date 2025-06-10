import SwiftUI

public extension View {
    func typography(_ t: UIFont.Typography) -> some View {
        modifier(TypographyViewModifier(typography: t))
    }
}

struct TypographyKey: EnvironmentKey {
    static let defaultValue: UIFont.Typography = .M1.bold
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

    static func amaticSC(size: CGFloat, weight: UIFont.Weight = .light) -> UIFont {
        let name: String = {
            switch weight {
            case .bold: return "AmaticSC-Bold"
            case .regular: return "AmaticSC-Regular"
            case .light: return "AmaticSC-Regular"
            default: return "AmaticSC-Regular"
            }
        }()

        return .init(name: name, size: size) ?? .amaticSC(size: size)
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

    static func amaticSC(
        size: CGFloat,
        weight: UIFont.Weight = .light,
        lineHeght: CGFloat
    ) -> Self {
        .init(font: .amaticSC(size: size,weight: weight), lineHeight: lineHeght)
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
    struct M1 {
        public static let superBold = UIFont.Typography.amaticSC(
            size: 56,
            weight: .bold,
            lineHeght: 74
        )

        public static let bold = UIFont.Typography.amaticSC(
            size: 34,
            weight: .bold,
            lineHeght: 42
        )

        public static let regular = UIFont.Typography.amaticSC(
            size: 20,
            weight: .light,
            lineHeght: 24
        )
    }
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

