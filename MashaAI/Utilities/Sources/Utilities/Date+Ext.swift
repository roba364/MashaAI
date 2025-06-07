import Foundation

public extension Date {
    /// Combines the date components from `birthDate` with the time components from `birthTime` without additional timezone adjustments.
    static func combine(birthDate: Date, birthTime: Date) -> Date? {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(secondsFromGMT: 0)! // Set Calendar to UTC

        // Extract date components (year, month, day) from birthDate in UTC
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: birthDate)

        // Extract time components (hour, minute) from birthTime in UTC
        let timeComponents = calendar.dateComponents([.hour, .minute], from: birthTime)

        // Combine the components into a new DateComponents instance
        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        combinedComponents.timeZone = TimeZone(secondsFromGMT: 0) // Explicitly set to UTC

        // Return the combined date in UTC
        return calendar.date(from: combinedComponents)
    }

    /// Formats a Date object into an ISO 8601 string in UTC.
    static func formattedISODate(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0) // Ensure UTC
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
}
