import Foundation
import CoreGraphics
import Testing
@testable import Oncey

struct TimelineViewModelTests {
    @Test func availableYearsAreDeduplicatedInDescendingOrder() {
        let viewModel = MomentsViewModel()
        let calendar = makeCalendar()
        let album = Album(name: "Trips")

        let newest = makeMoment(
            album: album,
            createdAt: makeDate(year: 2026, month: 4, day: 11, hour: 10),
            updatedAt: makeDate(year: 2026, month: 4, day: 11, hour: 10)
        )
        let sameYearOlder = makeMoment(
            album: album,
            createdAt: makeDate(year: 2026, month: 1, day: 5, hour: 8),
            updatedAt: makeDate(year: 2026, month: 1, day: 5, hour: 8)
        )
        let older = makeMoment(
            album: album,
            createdAt: makeDate(year: 2025, month: 12, day: 30, hour: 9),
            updatedAt: makeDate(year: 2025, month: 12, day: 30, hour: 9)
        )

        let years = viewModel.availableYears(
            from: [older, newest, sameYearOlder],
            calendar: calendar
        )

        #expect(years == [2026, 2025])
    }

    @Test func sectionsGroupMomentsByYearInDescendingOrder() {
        let viewModel = MomentsViewModel()
        let calendar = makeCalendar()
        let yearFormatter = makeFormatter(dateFormat: "yyyy")
        let album = Album(name: "Trips")

        let older = makeMoment(
            album: album,
            createdAt: makeDate(year: 2025, month: 12, day: 30, hour: 9),
            updatedAt: makeDate(year: 2025, month: 12, day: 30, hour: 9)
        )
        let sameDayEarlierUpdate = makeMoment(
            album: album,
            createdAt: makeDate(year: 2026, month: 4, day: 11, hour: 10),
            updatedAt: makeDate(year: 2026, month: 4, day: 11, hour: 10)
        )
        let sameDayLaterUpdate = makeMoment(
            album: album,
            createdAt: makeDate(year: 2026, month: 4, day: 11, hour: 10),
            updatedAt: makeDate(year: 2026, month: 4, day: 11, hour: 12)
        )

        let sections = viewModel.sections(
            from: [older, sameDayEarlierUpdate, sameDayLaterUpdate],
            calendar: calendar,
            yearFormatter: yearFormatter
        )

        #expect(sections.map(\.title) == ["2026", "2025"])
        #expect(sections[0].moments.map(\.id) == [sameDayLaterUpdate.id, sameDayEarlierUpdate.id])
        #expect(sections[1].moments.map(\.id) == [older.id])
    }

    @Test func monthDayAndYearFormattingUseProvidedFormatters() {
        let viewModel = MomentsViewModel()
        let album = Album(name: "Dates")
        let moment = makeMoment(
            album: album,
            createdAt: makeDate(year: 2026, month: 4, day: 27, hour: 8),
            updatedAt: makeDate(year: 2026, month: 4, day: 27, hour: 8)
        )
        let monthDayFormatter = makeFormatter(dateFormat: "MM-dd")
        let yearFormatter = makeFormatter(dateFormat: "yyyy")

        #expect(viewModel.monthDayText(for: moment, formatter: monthDayFormatter) == "04-27")
        #expect(viewModel.sections(from: [moment], calendar: makeCalendar(), yearFormatter: yearFormatter).map(\.title) == ["2026"])
    }

    @Test func albumNameFallsBackWhenRelationshipIsMissing() {
        let viewModel = MomentsViewModel()
        let album = Album(name: "Original")
        let moment = makeMoment(
            album: album,
            createdAt: makeDate(year: 2026, month: 4, day: 27, hour: 8),
            updatedAt: makeDate(year: 2026, month: 4, day: 27, hour: 8)
        )
        moment.album = nil

        #expect(viewModel.albumNameText(for: moment) == "Unknown Album")
    }

    @Test func waterfallSectionKeepsYearGroupingAndBalancesShorterColumnFirst() {
        let viewModel = MomentsViewModel()
        let calendar = makeCalendar()
        let yearFormatter = makeFormatter(dateFormat: "yyyy")
        let album = Album(name: "Trips")

        let latestWide = makeMoment(
            album: album,
            createdAt: makeDate(year: 2026, month: 4, day: 27, hour: 12),
            updatedAt: makeDate(year: 2026, month: 4, day: 27, hour: 12),
            note: "Latest"
        )
        let middleTall = makeMoment(
            album: album,
            createdAt: makeDate(year: 2026, month: 4, day: 26, hour: 12),
            updatedAt: makeDate(year: 2026, month: 4, day: 26, hour: 12)
        )
        let olderMedium = makeMoment(
            album: album,
            createdAt: makeDate(year: 2026, month: 4, day: 25, hour: 12),
            updatedAt: makeDate(year: 2026, month: 4, day: 25, hour: 12)
        )

        let sections = viewModel.sections(
            from: [olderMedium, middleTall, latestWide],
            calendar: calendar,
            yearFormatter: yearFormatter
        )
        let waterfallSection = viewModel.waterfallSection(
            from: sections[0],
            itemWidth: 100,
            itemSpacing: 16,
            imageSizeResolver: { moment in
                switch moment.id {
                case latestWide.id:
                    CGSize(width: 200, height: 100)
                case middleTall.id:
                    CGSize(width: 100, height: 200)
                case olderMedium.id:
                    CGSize(width: 100, height: 120)
                default:
                    nil
                }
            }
        )

        #expect(waterfallSection.title == "2026")
        #expect(waterfallSection.columns.count == 2)
        #expect(waterfallSection.columns[0].moments.map(\.id) == [latestWide.id, olderMedium.id])
        #expect(waterfallSection.columns[1].moments.map(\.id) == [middleTall.id])
    }

    @Test func estimatedTileHeightFallsBackToDefaultAspectRatioWhenImageSizeIsMissing() {
        let viewModel = MomentsViewModel()
        let album = Album(name: "Fallback")
        let moment = makeMoment(
            album: album,
            createdAt: makeDate(year: 2026, month: 4, day: 27, hour: 8),
            updatedAt: makeDate(year: 2026, month: 4, day: 27, hour: 8)
        )

        let estimatedHeight = viewModel.estimatedTileHeight(
            for: moment,
            itemWidth: 120,
            imageSizeResolver: { _ in nil }
        )

        #expect(estimatedHeight == 166)
    }

    private func makeMoment(album: Album, createdAt: Date, updatedAt: Date, note: String = "") -> Moment {
        Moment(
            album: album,
            photo: "/tmp/\(UUID().uuidString).jpg",
            note: note,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    private func makeFormatter(dateFormat: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = makeCalendar()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = dateFormat
        return formatter
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
