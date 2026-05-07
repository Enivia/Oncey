//
//  AlbumMomentsViewModel.swift
//  Oncey
//

import Foundation

struct AlbumMomentsViewModel {
    let album: Album

    private static let yearCalendar = Calendar.autoupdatingCurrent

    var title: String {
        album.name
    }

    var moments: [Moment] {
        album.moments.sorted { $0.createdAt > $1.createdAt }
    }

    var availableYears: [Int] {
        var seenYears = Set<Int>()

        return moments.compactMap { moment in
            let year = Self.year(for: moment.createdAt)
            return seenYears.insert(year).inserted ? year : nil
        }
    }

    func resolvedCurrentMomentID(preferredCurrentMomentID: UUID?) -> UUID? {
        Self.resolvedCurrentMomentID(in: moments, preferredCurrentMomentID: preferredCurrentMomentID)
    }

    func resolvedCurrentMomentID(currentMomentID: UUID?, preferredCurrentMomentID: UUID?) -> UUID? {
        Self.resolvedCurrentMomentID(
            in: moments,
            currentMomentID: currentMomentID,
            preferredCurrentMomentID: preferredCurrentMomentID
        )
    }

    func timestampText(for moment: Moment) -> String {
        AppDateFormatters.momentTimestamp.string(from: moment.createdAt)
    }

    func year(for momentID: UUID?) -> Int? {
        guard let momentID,
              let moment = moments.first(where: { $0.id == momentID }) else {
            return nil
        }

        return Self.year(for: moment.createdAt)
    }

    func latestMomentID(inYear year: Int) -> UUID? {
        moments.first { Self.year(for: $0.createdAt) == year }?.id
    }

    static func resolvedCurrentMomentID(in moments: [Moment], preferredCurrentMomentID: UUID?) -> UUID? {
        guard let firstMoment = moments.first else {
            return nil
        }

        guard let preferredCurrentMomentID,
              moments.contains(where: { $0.id == preferredCurrentMomentID }) else {
            return firstMoment.id
        }

        return preferredCurrentMomentID
    }

    static func resolvedCurrentMomentID(
        in moments: [Moment],
        currentMomentID: UUID?,
        preferredCurrentMomentID: UUID?
    ) -> UUID? {
        if let currentMomentID,
           moments.contains(where: { $0.id == currentMomentID }) {
            return currentMomentID
        }

        return resolvedCurrentMomentID(
            in: moments,
            preferredCurrentMomentID: preferredCurrentMomentID
        )
    }

    private static func year(for date: Date) -> Int {
        yearCalendar.component(.year, from: date)
    }
}
