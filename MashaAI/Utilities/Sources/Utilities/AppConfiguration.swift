import Foundation

public enum AppConfiguration {
    case debug
    case appStore

    // This can be used to add debug statements.
    public static var isDebug: Bool {
#if DEBUG
        return true
#else
        return false
#endif
    }

    public static var current: AppConfiguration {
        if isDebug {
            return .debug
        } else {
            return .appStore
        }
    }

    public static var isIosVersionUpper17: Bool {
        if #available(iOS 17.0, *) {
            return true
        } else {
            return false
        }
    }
}
