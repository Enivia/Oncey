import Foundation
import Testing
@testable import Oncey

struct AlbumMomentsViewModelTests {
    @Test func availableYearsReturnsDistinctYearsInDescendingOrder() {
        let album = Album(name: "Trip")
        let recent2026 = makeMoment(
            album: album,
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!,
            createdAt: makeDate(year: 2026, month: 5, day: 3, hour: 9)
        )
        let older2026 = makeMoment(
            album: album,
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
            createdAt: makeDate(year: 2026, month: 1, day: 3, hour: 9)
        )
        let recent2025 = makeMoment(
            album: album,
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
            createdAt: makeDate(year: 2025, month: 8, day: 3, hour: 9)
        )
        let recent2024 = makeMoment(
            album: album,
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            createdAt: makeDate(year: 2024, month: 7, day: 3, hour: 9)
        )
        album.moments = [recent2024, older2026, recent2025, recent2026]

        let viewModel = AlbumMomentsViewModel(album: album)

        #expect(viewModel.availableYears == [2026, 2025, 2024])
    }

    @Test func latestMomentIDReturnsMostRecentMomentInRequestedYear() {
        let album = Album(name: "Trip")
        let recent2025 = makeMoment(
            album: album,
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
            createdAt: makeDate(year: 2025, month: 10, day: 3, hour: 9)
        )
        let older2025 = makeMoment(
            album: album,
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            createdAt: makeDate(year: 2025, month: 3, day: 3, hour: 9)
        )
        let recent2024 = makeMoment(
            album: album,
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            createdAt: makeDate(year: 2024, month: 7, day: 3, hour: 9)
        )
        album.moments = [older2025, recent2024, recent2025]

        let viewModel = AlbumMomentsViewModel(album: album)

        #expect(viewModel.latestMomentID(inYear: 2025) == recent2025.id)
        #expect(viewModel.latestMomentID(inYear: 2024) == recent2024.id)
        #expect(viewModel.latestMomentID(inYear: 2023) == nil)
    }

    @Test func resolvedCurrentMomentIDUsesPreferredMomentWhenCurrentMomentIsNil() {
        let album = Album(name: "Trip")
        let latestMoment = makeMoment(
            album: album,
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            createdAt: makeDate(year: 2026, month: 5, day: 3, hour: 9)
        )
        let middleMoment = makeMoment(
            album: album,
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            createdAt: makeDate(year: 2026, month: 5, day: 2, hour: 9)
        )
        let oldestMoment = makeMoment(
            album: album,
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            createdAt: makeDate(year: 2026, month: 5, day: 1, hour: 9)
        )
        album.moments = [oldestMoment, middleMoment, latestMoment]

        #expect(
            AlbumMomentsViewModel.resolvedCurrentMomentID(
                in: album.moments,
                currentMomentID: nil,
                preferredCurrentMomentID: middleMoment.id
            ) == middleMoment.id
        )
    }

    @Test func resolvedCurrentMomentIDPreservesCurrentMomentWhenStillPresent() {
        let album = Album(name: "Trip")
        let latestMoment = makeMoment(
            album: album,
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            createdAt: makeDate(year: 2026, month: 5, day: 3, hour: 9)
        )
        let middleMoment = makeMoment(
            album: album,
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            createdAt: makeDate(year: 2026, month: 5, day: 2, hour: 9)
        )
        let oldestMoment = makeMoment(
            album: album,
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            createdAt: makeDate(year: 2026, month: 5, day: 1, hour: 9)
        )
        album.moments = [oldestMoment, middleMoment, latestMoment]

        #expect(
            AlbumMomentsViewModel.resolvedCurrentMomentID(
                in: album.moments,
                currentMomentID: oldestMoment.id,
                preferredCurrentMomentID: middleMoment.id
            ) == oldestMoment.id
        )
    }

    @Test func resolvedCurrentMomentIDPrefersRequestedMomentWhenPresent() {
        let album = Album(name: "Trip")
        let latestMoment = makeMoment(
            album: album,
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            createdAt: makeDate(year: 2026, month: 5, day: 2, hour: 9)
        )
        let olderMoment = makeMoment(
            album: album,
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            createdAt: makeDate(year: 2026, month: 5, day: 1, hour: 9)
        )
        album.moments = [olderMoment, latestMoment]

        let viewModel = AlbumMomentsViewModel(album: album)

        #expect(viewModel.resolvedCurrentMomentID(preferredCurrentMomentID: olderMoment.id) == olderMoment.id)
    }

    @Test func resolvedCurrentMomentIDFallsBackToLatestMomentWhenRequestedMomentMissing() {
        let album = Album(name: "Trip")
        let latestMoment = makeMoment(
            album: album,
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            createdAt: makeDate(year: 2026, month: 5, day: 2, hour: 9)
        )
        let olderMoment = makeMoment(
            album: album,
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            createdAt: makeDate(year: 2026, month: 5, day: 1, hour: 9)
        )
        album.moments = [olderMoment, latestMoment]

        let viewModel = AlbumMomentsViewModel(album: album)

        #expect(viewModel.resolvedCurrentMomentID(preferredCurrentMomentID: UUID()) == latestMoment.id)
    }

    private func makeMoment(album: Album, id: UUID, createdAt: Date) -> Moment {
        Moment(
            id: id,
            album: album,
            photo: "/tmp/\(id.uuidString).jpg",
            createdAt: createdAt,
            updatedAt: createdAt
        )
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