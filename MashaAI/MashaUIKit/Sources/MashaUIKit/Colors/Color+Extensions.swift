import SwiftUI
import Utilities

public extension Color {
    init(hex: UInt, alpha: Double) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }

    init(hex: HexValue) {
        self.init(hex: hex.wrappedValue, alpha: 1)
    }

    var hex: UInt {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0
        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: nil)
        return UInt(red * 255) << 16 | UInt(green * 255) << 8 | UInt(blue * 255)
    }
}

public extension UIColor {

    convenience init?(hexString: String) {
        guard let hex = HexValue(hexString) else {
            return nil
        }
        self.init(hex)
    }

    convenience init(_ hex: HexValue, alpha: CGFloat = 1) {
        self.init(
            red: (hex.wrappedValue >> 16) & 0xFF,
            green: (hex.wrappedValue >> 8) & 0xFF,
            blue: hex.wrappedValue & 0xFF,
            alpha: alpha
        )
    }

    convenience init(red: Int, green: Int, blue: Int, alpha: CGFloat = 1.0) {
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: alpha)
    }

    convenience init(red: UInt, green: UInt, blue: UInt, alpha: CGFloat = 1.0) {
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: alpha)
    }

    @objc
    static var placeholder: UIColor {
        return UIColor(white: 0.7, alpha: 1)
    }
}
