//
//  AlbumsViewModel.swift
//  Oncey
//

import Observation
import Foundation

@MainActor
@Observable
final class AlbumsViewModel {
    private static let timelineNodeLimit = 6
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    func latestMoment(for album: Album) -> Moment? {
        album.moments.max { lhs, rhs in
            if lhs.createdAt == rhs.createdAt {
                return lhs.updatedAt < rhs.updatedAt
            }

            return lhs.createdAt < rhs.createdAt
        }
    }

    func coverPhotoPath(for album: Album) -> String? {
        latestMoment(for: album)?.photo
    }

    func layerCount(for album: Album) -> Int {
        max(1, min(album.moments.count, 5))
    }

    func momentCountText(for album: Album) -> String {
        let count = album.moments.count
        return count == 1 ? "1 Moment" : "\(count) Moments"
    }

    func nextReminderAlbum(
        in albums: [Album],
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> Album? {
        let today = calendar.startOfDay(for: referenceDate)
        guard let deadline = calendar.date(byAdding: .day, value: 10, to: today) else {
            return nil
        }

        return albums
            .filter { album in
                guard let remindAt = album.remindAt else {
                    return false
                }

                let reminderDay = calendar.startOfDay(for: remindAt)
                return reminderDay >= today && reminderDay <= deadline
            }
            .min { lhs, rhs in
                guard let lhsDate = lhs.remindAt, let rhsDate = rhs.remindAt else {
                    return lhs.createdAt < rhs.createdAt
                }

                if lhsDate == rhsDate {
                    return lhs.createdAt < rhs.createdAt
                }

                return lhsDate < rhsDate
            }
    }

    func latestMomentCreatedText(for album: Album) -> String? {
        guard let latestMoment = latestMoment(for: album) else {
            return nil
        }

        return Self.dateFormatter.string(from: latestMoment.createdAt)
    }

    func reminderCountdownText(
        for album: Album,
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> String? {
        guard let remindAt = album.remindAt else {
            return nil
        }

        return relativeReminderText(
            to: remindAt,
            referenceDate: referenceDate,
            futureSuffix: "later",
            calendar: calendar
        )
    }

    func reminderBannerText(
        for album: Album,
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> String? {
        guard let remindAt = album.remindAt else {
            return nil
        }

        guard let summary = relativeReminderText(
            to: remindAt,
            referenceDate: referenceDate,
            futureSuffix: "remaining",
            calendar: calendar
        ) else {
            return nil
        }

        if summary == "Today" {
            return "Today, ready to go back and take a photo?"
        }

        return "\(summary), ready to go back and take a photo?"
    }

    func displayedMomentNodeCount(for album: Album) -> Int {
        let limit = album.hasReminder ? Self.timelineNodeLimit - 1 : Self.timelineNodeLimit
        return min(album.moments.count, limit)
    }

    func showsReminderNode(for album: Album) -> Bool {
        album.hasReminder
    }

    private func relativeReminderText(
        to targetDate: Date,
        referenceDate: Date,
        futureSuffix: String,
        calendar: Calendar
    ) -> String? {
        let startReference = calendar.startOfDay(for: referenceDate)
        let startTarget = calendar.startOfDay(for: targetDate)

        if startReference == startTarget {
            return "Today"
        }

        let isFuture = startTarget > startReference
        let fromDate = isFuture ? startReference : startTarget
        let toDate = isFuture ? startTarget : startReference
        let components = calendar.dateComponents([.year, .month, .weekOfYear, .day], from: fromDate, to: toDate)

        let valueAndUnit = normalizedReminderComponent(from: components)
        let suffix = isFuture ? futureSuffix : "ago"
        return "\(valueAndUnit.value) \(unitText(for: valueAndUnit.unit, count: valueAndUnit.value)) \(suffix)"
    }

    private func normalizedReminderComponent(from components: DateComponents) -> (value: Int, unit: AlbumReminderUnit) {
        if let years = components.year, years >= 1 {
            return (years, .year)
        }

        if let months = components.month, months >= 1 {
            return (months, .month)
        }

        if let weeks = components.weekOfYear, weeks >= 1 {
            return (weeks, .week)
        }

        return (max(1, components.day ?? 0), .day)
    }

    private func unitText(for unit: AlbumReminderUnit, count: Int) -> String {
        let base: String

        switch unit {
        case .day:
            base = "day"
        case .week:
            base = "week"
        case .month:
            base = "month"
        case .year:
            base = "year"
        }

        return count == 1 ? base : "\(base)s"
    }
}
