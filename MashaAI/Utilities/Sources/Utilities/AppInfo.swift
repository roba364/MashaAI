import Foundation

public struct AppInfo {
    public struct Key { }
    public struct VideoURL {}
    public struct URLs {}
    public struct Constants {}
    public struct Bundle {}
    public struct PDF {}
    public struct Lottie {}
}

public extension AppInfo.URLs {
    static let privacy = URL(string: "https://evo-ai-tech.com/privacy-policy")!
    static let terms = URL(string: "https://evo-ai-tech.com/terms-conditions")!
}

public extension AppInfo.Constants {
    static let appName = Bundle.main.appName
}

public extension AppInfo.Bundle {
    static let appName = Bundle.main.appName
    static let displayName = Bundle.main.displayName
    static let versionLong = Bundle.main.appVersionLong
    static let versionShort = Bundle.main.appVersionLong
    static let currentLanguage = Bundle.main.currentLanguage
    static let buildNumber = Bundle.main.appBuild
    static func tourAIUrl(for language: String) -> URL {
        Bundle.main.url(forResource: "tour_ai_\(language)", withExtension: ".mp3")!
    }
}

public extension AppInfo.Lottie {
    static let mainScene = "main_scene"
    static let talentRegistration = "talent_registration"
    static let onboardingDna = "onboarding_dna"
}

extension Bundle {
    var appName: String           { getInfo("CFBundleName") }
    var displayName: String       { getInfo("CFBundleDisplayName") }
    var language: String          { getInfo("CFBundleDevelopmentRegion") }
    var identifier: String        { getInfo("CFBundleIdentifier") }
    var copyright: String         { getInfo("NSHumanReadableCopyright").replacingOccurrences(of: "\\\\n", with: "\n") }

    var appBuild: String          { getInfo("CFBundleVersion") }
    var appVersionLong: String    { getInfo("CFBundleShortVersionString") }
    var appVersionShort: String   { getInfo("CFBundleShortVersion") }
    var currentLanguage: String   { currentLocaleLanguage() }

    fileprivate func getInfo(_ str: String) -> String { infoDictionary?[str] as? String ?? "⚠️" }
    fileprivate func currentLocaleLanguage() -> String {
        switch Locale.preferredLanguageCode {
        case "en": return "en"
        case "ru": return "ru"
        default: return "en"
        }
    }
}

extension Locale {
    static var preferredLanguageCode: String {
        guard let preferredLanguage = preferredLanguages.first,
              let code = Locale(identifier: preferredLanguage).languageCode else {
            return "en"
        }
        return code
    }
}

public extension AppInfo.Key {
    static let appleId = "id6737269204"
}
