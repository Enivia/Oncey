import Foundation
import Testing
@testable import Oncey

@MainActor
struct AlbumsViewModelTests {
    @Test func latestMomentAndAlbumCreatedTextsUseProvidedFormatter() {
        let viewModel = AlbumsViewModel()
        let formatter = DateFormatter()
        formatter.calendar = makeCalendar()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"

        let album = makeAlbum(
            name: "Dates",
            momentDates: [
                makeDate(year: 2026, month: 4, day: 11, hour: 9),
                makeDate(year: 2026, month: 4, day: 27, hour: 21)
            ]
        )

        #expect(viewModel.albumCreatedText(for: album, formatter: formatter) == "2026-04-01")
    }

    @Test func nextReminderAlbumSelectsClosestUpcomingReminderWithinTenDays() {
        let viewModel = AlbumsViewModel()
        let calendar = makeCalendar()
        let referenceDate = makeDate(year: 2026, month: 4, day: 27, hour: 10)
        let nearest = makeAlbum(
            name: "Nearest",
            remindAt: makeDate(year: 2026, month: 4, day: 30, hour: 10)
        )
        let later = makeAlbum(
            name: "Later",
            remindAt: makeDate(year: 2026, month: 5, day: 4, hour: 10)
        )
        let expired = makeAlbum(
            name: "Expired",
            remindAt: makeDate(year: 2026, month: 4, day: 26, hour: 10)
        )
        let tooFar = makeAlbum(
            name: "Too Far",
            remindAt: makeDate(year: 2026, month: 5, day: 8, hour: 10)
        )

    let result = viewModel.nextReminderAlbum(in: [later, tooFar, expired, nearest], referenceDate: referenceDate, calendar: calendar)

        #expect(result?.id == nearest.id)
    }

    @Test func reminderCountdownTextUsesTodayLaterAndAgoStates() {
        let viewModel = AlbumsViewModel()
        let calendar = makeCalendar()
        let referenceDate = makeDate(year: 2026, month: 4, day: 27, hour: 10)
        let today = makeAlbum(
            name: "Today",
            remindAt: makeDate(year: 2026, month: 4, day: 27, hour: 18)
        )
        let future = makeAlbum(
            name: "Future",
            remindAt: makeDate(year: 2026, month: 4, day: 30, hour: 10)
        )
        let expired = makeAlbum(
            name: "Expired",
            remindAt: makeDate(year: 2026, month: 4, day: 20, hour: 10)
        )

    #expect(viewModel.reminderCountdownText(for: today, referenceDate: referenceDate, calendar: calendar) == "Today")
    #expect(viewModel.reminderCountdownText(for: future, referenceDate: referenceDate, calendar: calendar) == "3 days later")
    #expect(viewModel.reminderCountdownText(for: expired, referenceDate: referenceDate, calendar: calendar) == "1 week ago")
    }

    @Test func reminderCountdownTextPromotesMonthAndYearUnits() {
        let viewModel = AlbumsViewModel()
        let calendar = makeCalendar()
        let referenceDate = makeDate(year: 2026, month: 4, day: 27, hour: 10)
        let monthAlbum = makeAlbum(
            name: "Month",
            remindAt: makeDate(year: 2026, month: 6, day: 10, hour: 10)
        )
        let yearAlbum = makeAlbum(
            name: "Year",
            remindAt: makeDate(year: 2027, month: 5, day: 1, hour: 10)
        )

    #expect(viewModel.reminderCountdownText(for: monthAlbum, referenceDate: referenceDate, calendar: calendar) == "1 month later")
    #expect(viewModel.reminderCountdownText(for: yearAlbum, referenceDate: referenceDate, calendar: calendar) == "1 year later")
    }

    @Test func timelineNodesCapAtSixIncludingReminderNode() {
        let viewModel = AlbumsViewModel()
        let calendar = makeCalendar()
        let referenceDate = makeDate(year: 2026, month: 4, day: 27, hour: 10)
        let album = makeAlbum(
            name: "Timeline",
            remindAt: makeDate(year: 2026, month: 5, day: 1, hour: 10),
            momentDates: [
                makeDate(year: 2026, month: 4, day: 20, hour: 10),
                makeDate(year: 2026, month: 4, day: 21, hour: 10),
                makeDate(year: 2026, month: 4, day: 22, hour: 10),
                makeDate(year: 2026, month: 4, day: 23, hour: 10),
                makeDate(year: 2026, month: 4, day: 24, hour: 10),
                makeDate(year: 2026, month: 4, day: 25, hour: 10),
                makeDate(year: 2026, month: 4, day: 26, hour: 10)
            ]
        )

        #expect(viewModel.displayedMomentNodeCount(for: album) == 5)
        #expect(viewModel.showsReminderNode(for: album))
        #expect(viewModel.reminderBannerText(for: album, referenceDate: referenceDate, calendar: calendar) == "4 days remaining, ready to go back and take a photo?")
    }

    private func makeAlbum(
        name: String,
        remindAt: Date? = nil,
        momentDates: [Date] = []
    ) -> Album {
        let album = Album(
            name: name,
            remindValue: remindAt == nil ? nil : 1,
            remindUnit: remindAt == nil ? nil : .day,
            remindAt: remindAt,
            createdAt: makeDate(year: 2026, month: 4, day: 1, hour: 10),
            updatedAt: makeDate(year: 2026, month: 4, day: 1, hour: 10)
        )

        for date in momentDates {
            _ = Moment(
                album: album,
                photo: "/tmp/\(UUID().uuidString).jpg",
                createdAt: date,
                updatedAt: date
            )
        }

        return album
    }

    private func makeDate(year: Int, month: Int, day: Int, hour: Int) -> Date {
        var components = DateComponents()
        components.calendar = makeCalendar()
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = 0
        components.second = 0
        return components.date!
    }

    private func makeCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
}
