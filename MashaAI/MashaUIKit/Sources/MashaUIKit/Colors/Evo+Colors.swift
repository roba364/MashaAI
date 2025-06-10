import SwiftUI

public extension Color {
    enum Palette {
        public static var yellowNotActive: Color { .init(hex: 0xFFD15C) }
        public static var yellowActive: Color { .init(hex: 0xFFE4A1) }

        public static func colorFromHexString(_ hexString: String) -> Color {
            Color(UIColor(hexString: "0x\(hexString)") ?? .white)
        }

        public static func colorFromHxString(_ hexString: String?) -> Color {
            // Ensure the hex string is not nil
            guard let hexString = hexString else { return .black }

            // Clean up the hex string by removing whitespaces and leading #
            var hexSanitized = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
            hexSanitized = hexSanitized.hasPrefix("#") ? String(hexSanitized.dropFirst()) : hexSanitized

            // Ensure the string is the correct length (6 for RGB or 8 for RGBA)
            guard hexSanitized.count == 6 || hexSanitized.count == 8 else { return .black }

            // Convert the sanitized hex string to a UInt
            var hexValue: UInt64 = 0
            let scanner = Scanner(string: hexSanitized)

            // Scan the hex string as a UInt64
            if scanner.scanHexInt64(&hexValue) {
                // Use the `Color(hex: UInt, alpha: Double)` initializer
                return Color(hex: UInt(hexValue), alpha: 1.0)
            }

            // Return a fallback color if the conversion fails
            return .black
        }
    }
    
    static let palette = Palette.self
}
