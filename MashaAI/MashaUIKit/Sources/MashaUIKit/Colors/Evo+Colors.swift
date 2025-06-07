import SwiftUI

public extension Color {
    enum Palette {
        public static var mainBackground: Color { .init(hex: 0x0C0B14) }
        public static var black800: Color { .init(hex: 0x110D1C) }
        public static var black900: Color { .init(hex: 0x020204) }
        public static var primary50: Color { .init(hex: 0xFFFFFF).opacity(0.05) }
        public static var primary100: Color { .init(hex: 0xFFFFFF).opacity(0.1) }
        public static var primary500: Color { .init(hex: 0xFFFFFF).opacity(0.6) }
        public static var primary400: Color { .init(hex: 0xFFFFFF).opacity(0.5) }
        public static var primary700: Color { .init(hex: 0xFFFFFF).opacity(0.7) }
        public static var primary800: Color { .init(hex: 0xFFFFFF).opacity(0.9) }
        public static var meditationBtnBackground: Color { .init(hex: 0xEFF8FF) }
        public static var primary900: Color { .white }
        public static var ok100: Color { .init(hex: 0x2CF3CF).opacity(0.1) }
        public static var ok900: Color { .init(hex: 0x2CF3CF) }
        public static var error100: Color { .init(hex: 0xF3246F).opacity(0.1) }
        public static var error900: Color { .init(hex: 0xF3246F) }
        public static var alert900: Color { .init(hex: 0xFFCD1B) }
        public static var compatabilityGreen: Color { .init(hex: 0x14CFAD) }
        public static var compatabilityPurple: Color { .init(hex: 0xB05EF1) }
        public static var compatabilityOrange: Color { .init(hex: 0xF1A30F) }
        public static var compatabilityPink: Color { .init(hex: 0xF64791) }
        public static var txSecondary: Color { .init(hex: 0xFFFFFF).opacity(0.5) }
        public static var colorTSecondary: Color { .init(hex: 0xFFFFFF).opacity(0.4) }
        public static var tabBarBackground: Color { .init(hex: 0x0B0A10) }
        public static var tabBarButtonNotSelected: Color { .init(hex: 0xE9E9E9) }
        public static var primaryOverlay: Color { .init(hex: 0x398FDE) }
        public static var colorAction500: Color { .init(hex: 0x2FA5C5) }
        public static var mainScreenBackground: Color { .init(hex: 0x110D1C) }
        public static var closeBtn: Color { .init(hex: 0x767680) }
        public static var splash: Color { .init(hex: 0x1B192A) }
        public static var txInvert: Color { .init(hex: 0x20204) }
        public static var d9d9d9: Color { .init(hex: 0xD9D9D9) }
        public static var talentGreen: Color { .init(hex: 0x209294) }
        public static var talentBlue: Color { .init(hex: 0x4466EA) }
        public static var talentViolet: Color { .init(hex: 0x601DC5) }
        public static var talentRed: Color { .init(hex: 0xAB2620) }
        public static var talentPink: Color { .init(hex: 0xB3229C) }
        public static var talentYellow: Color { .init(hex: 0xD78E02) }
        public static var radial1: Color { .init(hex: 0x1C89D9).opacity(0.57) }
        public static var radial2: Color { .init(hex: 0x854CFF).opacity(0.26) }
        public static var radial3: Color { .init(hex: 0xE785FF).opacity(0.0) }
        public static var aminoBg: Color { .init(hex: 0x682530) }
        public static var aminoPreviewBg: Color { .init(hex: 0xE8735B) }
        public static var bubbleMy: Color { .init(hex: 0x282337) }
        public static var bubbleAI: Color { .init(hex: 0x191620) }
        public static var onboardingGoalsBackground: Color { .init(hex: 0x100E1A) }
        public static var onboardingTalentsBackground: Color { .init(hex: 0x0E0D14) }
        public static var paywallBackground: Color { .init(hex: 0x2D2936) }
        public static var startBtnBackground: Color { .init(hex: 0xEFF8FF) }
        public static var dailyAffirmation: Color { .init(hex: 0x1C135E) }
        public static var dnaCardBackground: Color { .init(hex: 0x080A15) }
        public static var paywallBannerBackground: Color { .init(hex: 0xFD8402) }
        public static var blob1: Color { .init(hex: 0x6B094F) }
        public static var blob2: Color { .init(hex: 0x341464) }
        public static var blob3: Color { .init(hex: 0x27122E) }
        public static var profileBackground: Color { .init(hex: 0x1F1329) }
        public static var talentsAffirmation: Color { .init(hex: 0x34245A) }
        public static var gradientSpecialTop: Color { .init(hex: 0x1E0C24) }
        public static var gradientSpecialBottom: Color { .init(hex: 0x150C1F) }
        public static var chatEvaTop: Color { .init(hex: 0xFF337E) }
        public static var chatEvaBottom: Color { .init(hex: 0x22D3CD) }
        public static var chatEvoBlur: Color { .init(hex: 0xFF3E75) }
        public static var voiceChatBlue: Color { .init(hex: 0x4FEAFF) }
        public static var voiceChatPink: Color { .init(hex: 0xF44CBF) }
        public static var voiceChatPink2: Color { .init(hex: 0xFF3C7A) }
        public static var voiceChatPink3: Color { .init(hex: 0xFFa5DB) }
        public static var voiceChatBlue2: Color { .init(hex: 0x00A8DF) }
        public static var voiceChatBlue3: Color { .init(hex: 0x007BDF) }
        public static var voiceChatBlue4: Color { .init(hex: 0x3CCBFF) }
        public static var voiceChatBlue5: Color { .init(hex: 0xA5ECFF) }

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

public extension Array where Element == Color {
    static let mainGradient: Self = [.palette.blob1]
}

public extension Array where Element == Gradient.Stop {
    static let mainGradient: Self = [
        .init(color: .palette.blob3, location: 0.0),
        .init(color: .palette.blob2, location: 1.0)
    ]
    static let levelReachedRainbow: Self = [
        .init(color: .palette.compatabilityPink, location: 0.0),
        .init(color: .palette.compatabilityGreen, location: 1.0)
    ]

    static let profileGradient: Self = [
        .init(color: .palette.blob2, location: 0.0),
        .init(color: .palette.blob2, location: 1.0)
    ]

    static let profileGradient2: Self = [
        .init(color: .palette.blob1, location: 0.0),
        .init(color: .palette.blob1, location: 1.0)
    ]

    static let profileGradient3: Self = [
        .init(color: .palette.blob3, location: 0),
        .init(color: .palette.blob3, location: 1.0)
    ]

    static let whatsNewGradient1: Self = [
        .init(color: .palette.blob2.opacity(0.4), location: 0.0),
        .init(color: .palette.blob2.opacity(0.4), location: 1.0)
    ]

    static let whatsNewGradient2: Self = [
        .init(color: .palette.blob1.opacity(0.4), location: 0.0),
        .init(color: .palette.blob1.opacity(0.4), location: 1.0)
    ]

    static let whatsNewGradient3: Self = [
        .init(color: .palette.blob3.opacity(0.4), location: 0),
        .init(color: .palette.blob3.opacity(0.4), location: 1.0)
    ]

    static let voiceChatPinkGradient: Self = [
        .init(color: .palette.voiceChatPink, location: 0.0),
        .init(color: .palette.voiceChatPink, location: 1.0)
    ]

    static let voiceChatPinkBlueGradient: Self = [
        .init(color: .palette.voiceChatPink, location: 0.0),
        .init(color: .palette.voiceChatBlue2, location: 0.8)
    ]

    static let voiceChatBlueGradient: Self = [
        .init(color: .palette.voiceChatBlue3, location: 0.0),
        .init(color: .palette.voiceChatBlue3, location: 1.0)
    ]
}
