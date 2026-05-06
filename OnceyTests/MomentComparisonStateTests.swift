import Foundation
import Testing
@testable import Oncey

struct MomentComparisonStateTests {
    @Test func defaultSelectionUsesCurrentMomentAndOldestMoment() {
        let album = Album(name: "Compare")
        let latestMoment = makeMoment(
            album: album,
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            createdAt: makeDate(year: 2026, month: 5, day: 1, hour: 9),
            updatedAt: makeDate(year: 2026, month: 5, day: 1, hour: 9)
        )
        let middleMoment = makeMoment(
            album: album,
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            createdAt: makeDate(year: 2026, month: 4, day: 20, hour: 9),
            updatedAt: makeDate(year: 2026, month: 4, day: 20, hour: 9)
        )
        let oldestMoment = makeMoment(
            album: album,
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            createdAt: makeDate(year: 2026, month: 4, day: 10, hour: 9),
            updatedAt: makeDate(year: 2026, month: 4, day: 10, hour: 9)
        )

        let state = MomentComparisonState(
            moments: [oldestMoment, middleMoment, latestMoment],
            currentMomentID: middleMoment.id
        )

        #expect(state.leadingMomentID == middleMoment.id)
        #expect(state.trailingMomentID == oldestMoment.id)
    }

    @Test func defaultSelectionUsesLatestOnLeadingSideWhenCurrentMomentIsOldest() {
        let album = Album(name: "Compare")
        let latestMoment = makeMoment(
            album: album,
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            createdAt: makeDate(year: 2026, month: 5, day: 1, hour: 9),
            updatedAt: makeDate(year: 2026, month: 5, day: 1, hour: 9)
        )
        let oldestMoment = makeMoment(
            album: album,
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            createdAt: makeDate(year: 2026, month: 4, day: 10, hour: 9),
            updatedAt: makeDate(year: 2026, month: 4, day: 10, hour: 9)
        )

        let state = MomentComparisonState(
            moments: [oldestMoment, latestMoment],
            currentMomentID: oldestMoment.id
        )

        #expect(state.leadingMomentID == latestMoment.id)
        #expect(state.trailingMomentID == oldestMoment.id)
    }

    @Test func selectingMomentCannotDuplicateOppositeSideSelection() {
        let album = Album(name: "Compare")
        let latestMoment = makeMoment(
            album: album,
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            createdAt: makeDate(year: 2026, month: 5, day: 1, hour: 9),
            updatedAt: makeDate(year: 2026, month: 5, day: 1, hour: 9)
        )
        let middleMoment = makeMoment(
            album: album,
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            createdAt: makeDate(year: 2026, month: 4, day: 20, hour: 9),
            updatedAt: makeDate(year: 2026, month: 4, day: 20, hour: 9)
        )
        let oldestMoment = makeMoment(
            album: album,
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            createdAt: makeDate(year: 2026, month: 4, day: 10, hour: 9),
            updatedAt: makeDate(year: 2026, month: 4, day: 10, hour: 9)
        )
        var state = MomentComparisonState(
            moments: [oldestMoment, middleMoment, latestMoment],
            currentMomentID: latestMoment.id
        )

        state.presentPicker(for: .leading)

        #expect(state.selectableMoments.map(\ .id) == [latestMoment.id, middleMoment.id])

        state.selectMoment(id: oldestMoment.id)

        #expect(state.leadingMomentID == latestMoment.id)
        #expect(state.isPickerExpanded)
        #expect(state.activeSide == .leading)

        state.selectMoment(id: middleMoment.id)

        #expect(state.leadingMomentID == middleMoment.id)
        #expect(!state.isPickerExpanded)
        #expect(state.activeSide == nil)
    }

    @Test func syncMomentsPreservesUnaffectedTrailingSelection() {
        let album = Album(name: "Compare")
        let latestMoment = makeMoment(
            album: album,
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
            createdAt: makeDate(year: 2026, month: 5, day: 2, hour: 9),
            updatedAt: makeDate(year: 2026, month: 5, day: 2, hour: 9)
        )
        let middleMoment = makeMoment(
            album: album,
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            createdAt: makeDate(year: 2026, month: 5, day: 1, hour: 9),
            updatedAt: makeDate(year: 2026, month: 5, day: 1, hour: 9)
        )
        let oldestMoment = makeMoment(
            album: album,
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            createdAt: makeDate(year: 2026, month: 4, day: 10, hour: 9),
            updatedAt: makeDate(year: 2026, month: 4, day: 10, hour: 9)
        )
        var state = MomentComparisonState(
            moments: [oldestMoment, middleMoment, latestMoment],
            currentMomentID: middleMoment.id
        )

        state.presentPicker(for: .leading)
        state.syncMoments([oldestMoment, latestMoment], preferredCurrentMomentID: latestMoment.id)

        #expect(state.leadingMomentID == latestMoment.id)
        #expect(state.trailingMomentID == oldestMoment.id)
    }

    @Test func stableOrderingUsesUpdatedAtThenIdentifierForSameCreationDate() {
        let album = Album(name: "Compare")
        let earlierUpdate = makeMoment(
            album: album,
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            createdAt: makeDate(year: 2026, month: 5, day: 1, hour: 9),
            updatedAt: makeDate(year: 2026, month: 5, day: 1, hour: 9)
        )
        let laterUpdate = makeMoment(
            album: album,
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            createdAt: makeDate(year: 2026, month: 5, day: 1, hour: 9),
            updatedAt: makeDate(year: 2026, month: 5, day: 1, hour: 10)
        )
        let sameUpdateHigherIdentifier = makeMoment(
            album: album,
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            createdAt: makeDate(year: 2026, month: 5, day: 1, hour: 9),
            updatedAt: makeDate(year: 2026, month: 5, day: 1, hour: 9)
        )

        let state = MomentComparisonState(
            moments: [earlierUpdate, laterUpdate, sameUpdateHigherIdentifier],
            currentMomentID: laterUpdate.id
        )

        #expect(state.moments.map(\ .id) == [laterUpdate.id, sameUpdateHigherIdentifier.id, earlierUpdate.id])
    }

    private func makeMoment(album: Album, id: UUID, createdAt: Date, updatedAt: Date) -> Moment {
        Moment(
            id: id,
            album: album,
            photo: "/tmp/\(id.uuidString).jpg",
            createdAt: createdAt,
            updatedAt: updatedAt
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