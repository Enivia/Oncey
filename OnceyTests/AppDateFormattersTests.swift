import Foundation
import Testing
@testable import Oncey

struct AppDateFormattersTests {
    @Test func compactDateFormatterUsesNumericLocalizedTemplate() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let formatter = AppDateFormatters.makeMomentCompactDateFormatter(
            locale: Locale(identifier: "en_US_POSIX"),
            timeZone: TimeZone(secondsFromGMT: 0)!,
            calendar: calendar
        )

        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = 2026
        components.month = 4
        components.day = 27
        components.hour = 8
        components.minute = 0
        components.second = 0

        #expect(formatter.string(from: components.date!) == "4/27/2026")
    }
}