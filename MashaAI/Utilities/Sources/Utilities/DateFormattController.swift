import Foundation

public final class DateFormatterController {

    public init() {}

    // MARK: - Shared Formatters
    /// Shared ISO8601DateFormatter instance with fractional seconds.
    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        // Include fractional seconds for higher precision if needed
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    /// Shared DateFormatter for 24-hour time format.
    private static let formatter24Hour: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        // Adjust the time zone as needed; here set to UTC
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    /// Shared DateFormatter for 12-hour time format.
    private static let formatter12Hour: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        // Adjust the time zone as needed; here set to UTC
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    /// Shared DateFormatter for user-friendly date format.
    private static let userDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        // e.g., "08 October 1993"
        formatter.dateFormat = "dd MMMM yyyy"
        formatter.locale = Locale(identifier: getCurrentLanguageCode())
        formatter.timeZone = TimeZone(secondsFromGMT: 0) // Set time zone to UTC
        return formatter
    }()

    // MARK: - Date and Time Formatting Methods

    /// Combines a date and time into a single ISO 8601 formatted string.
    ///
    /// - Parameters:
    ///   - dateOfBirth: The date component.
    ///   - timeOfBirth: The time component.
    ///   - timeZone: The time zone to use for combining.
    /// - Returns: An ISO 8601 formatted date string.
    static func formattedDateOfBirth(dateOfBirth: Date, timeOfBirth: Date, timeZone: TimeZone) -> String {
        let calendar = Calendar.current
        var dateComponents = calendar.dateComponents(in: timeZone, from: dateOfBirth)
        let timeComponents = calendar.dateComponents(in: timeZone, from: timeOfBirth)

        // Combine date and time components
        dateComponents.hour = timeComponents.hour
        dateComponents.minute = timeComponents.minute
        dateComponents.second = timeComponents.second

        guard let combinedDate = calendar.date(from: dateComponents) else {
            fatalError("Failed to combine date and time.")
        }

        // Format combinedDate to ISO 8601 format
        isoFormatter.timeZone = timeZone
        return isoFormatter.string(from: combinedDate)
    }
    
   public static func setDefaultTimeToProfile() -> Date {
        var defaultDate = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        defaultDate.timeZone = TimeZone(secondsFromGMT: 0)!
        defaultDate.hour = 12
        defaultDate.minute = 0
        
        let date = Calendar.current.date(from: defaultDate) ?? Date()
        
        return date
    }

    /// Parses an ISO 8601 formatted string into a Date object.
    ///
    /// - Parameter isoString: The ISO 8601 date string.
    /// - Returns: A Date object if parsing is successful; otherwise, `nil`.
    static func parseISODateString(_ isoString: String) -> Date? {
        return isoFormatter.date(from: isoString)
    }

    /// Determines if the current locale prefers a 24-hour time format.
    ///
    /// - Returns: `true` if 24-hour format is preferred; otherwise, `false`.
    public static func is24HourFormat() -> Bool {
        let locale = Locale.current
        let dateFormatter = DateFormatter()
        dateFormatter.locale = locale
        // "j" is the format specifier for locale-aware time format
        dateFormatter.setLocalizedDateFormatFromTemplate("j")
        let dateString = dateFormatter.string(from: Date())

        // If the date string contains AM/PM symbols, it's not 24-hour
        return !(dateString.contains(dateFormatter.amSymbol) || dateString.contains(dateFormatter.pmSymbol))
    }

    /// Formats a Date object to a user-friendly time string based on the user's preferred time format.
    ///
    /// - Parameter date: The Date object to format.
    /// - Returns: A formatted time string (e.g., "14:45" or "2:45 PM").
    public static func userTimeOfBirth(from date: Date) -> String {
        return is24HourFormat() ? formatter24Hour.string(from: date) : formatter12Hour.string(from: date)
    }

    /// Converts an ISO 8601 formatted string to a user-friendly time string based on the user's preferred time format.
    ///
    /// - Parameter isoString: The ISO 8601 date string.
    /// - Returns: A formatted time string (e.g., "14:45" or "2:45 PM") if parsing is successful; otherwise, `nil`.
    public static func timeOfBirth(from isoString: String) -> String? {
        guard let date = parseISODateString(isoString) else {
            return nil // Handle invalid ISO string as needed
        }
        return userTimeOfBirth(from: date)
    }

    /// Formats a Date object to a user-friendly date string.
    ///
    /// - Parameter date: The Date object to format.
    /// - Returns: A formatted date string (e.g., "08 October 1993").
    public static func userDateOfBirth(from date: Date) -> String {
        userDateFormatter.string(from: date)
    }

    /// Formats a Date object to a time string with AM/PM notation.
    ///
    /// - Parameter date: The Date object to format.
    /// - Returns: A formatted time string (e.g., "2:45 PM").
    public static func toAMorPM(from date: Date) -> String {
        // Utilize the 12-hour formatter
        return formatter12Hour.string(from: date)
    }
    
    public static func localizedCity(_ city: String) -> String {
        let currentLocale = Locale.current
        
        // Check if the string contains Cyrillic characters
        let isCyrillic = city.range(of: "[\u{0400}-\u{04FF}]", options: .regularExpression) != nil
        
        // Get the language code from the current locale
        let languageCode: String
        if #available(iOS 16, *) {
            languageCode = currentLocale.language.languageCode?.identifier ?? "en"
        } else {
            languageCode = currentLocale.languageCode ?? "en"
        }
        
        // If the text is in сyrillic and the current language is not russian
        if isCyrillic && languageCode != "ru" {
            if let latinName = city.applyingTransform(.toLatin, reverse: false) {
                return latinName.prefix(1).uppercased() + latinName.dropFirst()
            }
        }
        // If the text is in latin and the current language is russian
        else if !isCyrillic && languageCode == "ru" {
            if let cyrillicName = city.applyingTransform(.latinToCyrillic, reverse: false) {
                return cyrillicName
            }
        }
        return city
    }

    private static let newformatter12Hour: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        // Set the time zone to the current (local) time zone
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    private static let newformatter24Hour: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        // Set the time zone to the current (local) time zone
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    public static func newToAMorPM(from date: Date) -> String {
        if is24HourFormat() {
            return newformatter24Hour.string(from: date)
        } else {
            // Utilize the 12-hour formatter with local time zone
            return newformatter12Hour.string(from: date)
        }
    }

    static func getCurrentLanguageCode() -> String {
        guard let preferredLanguage = Locale.preferredLanguages.first else {
            return "en_US_POSIX"
        }

        let current: String
        if #available(iOS 16, *) {
            current = Locale(identifier: preferredLanguage).language.languageCode?.identifier ?? "en"
        } else {
            current = Locale(identifier: preferredLanguage).languageCode ?? "en"
        }

        switch current {
        case "ru": return "ru_RU"
        default: return "en_US_POSIX"
        }
    }
}
