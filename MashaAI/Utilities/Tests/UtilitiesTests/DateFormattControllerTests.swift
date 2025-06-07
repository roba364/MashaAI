import XCTest
@testable import Utilities

class DateFormatterControllerTests: XCTestCase {
    var dateFormatterController: DateFormatterController!

    override func setUp() {
        super.setUp()
        dateFormatterController = DateFormatterController()
    }

    override func tearDown() {
        dateFormatterController = nil
        super.tearDown()
    }

    func testFormattedDateOfBirth_withValidDateAndTime_returnsISOFormat() {
        // Given
        let dateOfBirth = Calendar.current.date(from: DateComponents(year: 2003, month: 10, day: 31))!
        let timeOfBirth = Calendar.current.date(from: DateComponents(hour: 12, minute: 1))!
        let timeZone = TimeZone(secondsFromGMT: 2 * 3600)! // GMT+2

        // When
        let isoDateString = DateFormatterController.formattedDateOfBirth(dateOfBirth: dateOfBirth, timeOfBirth: timeOfBirth, timeZone: timeZone)

        // Then
        XCTAssertEqual(isoDateString, "2003-10-31T12:01:00+02:00", "The ISO formatted date string should match expected output.")
    }

    func testFormattedDateOfBirth_withDifferentTimeZone_returnsCorrectISOFormat() {
        // Given
        let dateOfBirth = Calendar.current.date(from: DateComponents(year: 2003, month: 10, day: 31))!
        let timeOfBirth = Calendar.current.date(from: DateComponents(hour: 12, minute: 1))!
        let timeZone = TimeZone(secondsFromGMT: 0)! // GMT

        // When
        let isoDateString = DateFormatterController.formattedDateOfBirth(dateOfBirth: dateOfBirth, timeOfBirth: timeOfBirth, timeZone: timeZone)

        // Then
        XCTAssertEqual(isoDateString, "2003-10-31T12:01:00Z", "The ISO formatted date string should match expected output for GMT.")
    }

    func testFormattedDateOfBirth_withMidnightTimeOfBirth_returnsCorrectISOFormat() {
        // Given
        let dateOfBirth = Calendar.current.date(from: DateComponents(year: 2003, month: 10, day: 31))!
        let timeOfBirth = Calendar.current.date(from: DateComponents(hour: 0, minute: 0, second: 0))!
        let timeZone = TimeZone(secondsFromGMT: 2 * 3600)! // GMT+2

        // When
        let isoDateString = DateFormatterController.formattedDateOfBirth(dateOfBirth: dateOfBirth, timeOfBirth: timeOfBirth, timeZone: timeZone)

        // Then
        XCTAssertEqual(isoDateString, "2003-10-31T00:00:00+02:00", "The ISO formatted date string should match expected output for midnight time.")
    }

    func testDateComponentsFromISOFormattedString() {
        // Given
        let isoDateString = "2003-10-31T12:01:00.000+02:00"
        let expectedYear = 2003
        let expectedMonth = 10
        let expectedDay = 31

        // When
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = formatter.date(from: isoDateString) else {
            XCTFail("Failed to parse date from ISO string")
            return
        }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)

        // Then
        XCTAssertEqual(components.year, expectedYear, "The year component should be \(expectedYear)")
        XCTAssertEqual(components.month, expectedMonth, "The month component should be \(expectedMonth)")
        XCTAssertEqual(components.day, expectedDay, "The day component should be \(expectedDay)")
    }
}
