import Foundation
import UserNotifications

enum AlbumReminderError: LocalizedError {
    case invalidDate

    var errorDescription: String? {
        switch self {
        case .invalidDate:
            return "Couldn't calculate the reminder date."
        }
    }
}

enum AlbumReminderScheduleOutcome: Equatable {
    case scheduled
    case savedWithoutSystemAuthorization
}

struct AlbumReminderClient {
    var requestAuthorization: () async throws -> Bool
    var addRequest: (UNNotificationRequest) async throws -> Void
    var removeRequests: ([String]) -> Void

    nonisolated static func live() -> AlbumReminderClient {
        AlbumReminderClient(
            requestAuthorization: {
                try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
            },
            addRequest: { request in
                try await UNUserNotificationCenter.current().add(request)
            },
            removeRequests: { identifiers in
                let center = UNUserNotificationCenter.current()
                center.removePendingNotificationRequests(withIdentifiers: identifiers)
                center.removeDeliveredNotifications(withIdentifiers: identifiers)
            }
        )
    }
}

enum AlbumReminderService {
    static func reminderDate(
        from baseDate: Date = .now,
        value: Int,
        unit: AlbumReminderUnit,
        calendar: Calendar = .current
    ) -> Date? {
        var components = DateComponents()
        components.setValue(value, for: unit.calendarComponent)
        return calendar.date(byAdding: components, to: baseDate, wrappingComponents: false)
    }

    @discardableResult
    static func storeReminder(
        on album: Album,
        value: Int,
        unit: AlbumReminderUnit,
        baseDate: Date = .now,
        calendar: Calendar = .current
    ) throws -> Date {
        guard let remindAt = reminderDate(from: baseDate, value: value, unit: unit, calendar: calendar) else {
            throw AlbumReminderError.invalidDate
        }

        album.remindValue = value
        album.remindUnit = unit
        album.remindAt = remindAt
        album.updatedAt = baseDate
        return remindAt
    }

    static func applyReminder(
        for album: Album,
        value: Int,
        unit: AlbumReminderUnit,
        baseDate: Date = .now,
        calendar: Calendar = .current,
        client: AlbumReminderClient = AlbumReminderClient.live()
    ) async throws -> AlbumReminderScheduleOutcome {
        try storeReminder(on: album, value: value, unit: unit, baseDate: baseDate, calendar: calendar)
        return try await scheduleStoredReminder(for: album, client: client)
    }

    static func scheduleStoredReminder(
        for album: Album,
        client: AlbumReminderClient = AlbumReminderClient.live()
    ) async throws -> AlbumReminderScheduleOutcome {
        guard let remindAt = album.remindAt else {
            throw AlbumReminderError.invalidDate
        }

        let granted = try await client.requestAuthorization()
        guard granted else {
            return .savedWithoutSystemAuthorization
        }

        client.removeRequests([notificationIdentifier(for: album)])
        try await client.addRequest(makeRequest(for: album, remindAt: remindAt))
        return .scheduled
    }

    static func scheduleStoredReminder(
        for album: Album,
        authorizationGranted: Bool,
        client: AlbumReminderClient = AlbumReminderClient.live()
    ) async throws -> AlbumReminderScheduleOutcome {
        guard authorizationGranted else {
            return .savedWithoutSystemAuthorization
        }

        guard let remindAt = album.remindAt else {
            throw AlbumReminderError.invalidDate
        }

        client.removeRequests([notificationIdentifier(for: album)])
        try await client.addRequest(makeRequest(for: album, remindAt: remindAt))
        return .scheduled
    }

    static func removeScheduledReminder(
        for album: Album,
        client: AlbumReminderClient = AlbumReminderClient.live()
    ) {
        client.removeRequests([notificationIdentifier(for: album)])
    }

    static func clearReminder(
        for album: Album,
        updatedAt: Date = .now,
        client: AlbumReminderClient = AlbumReminderClient.live()
    ) {
        album.remindValue = nil
        album.remindUnit = nil
        album.remindAt = nil
        album.updatedAt = updatedAt
        removeScheduledReminder(for: album, client: client)
    }

    static func notificationIdentifier(for album: Album) -> String {
        "album-reminder-\(album.id.uuidString)"
    }

    private static func makeRequest(for album: Album, remindAt: Date) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = album.name.isEmpty ? "Time to come back" : "Return to \(album.name)"
        content.body = "Your next Oncey moment is waiting."
        content.sound = .default
        content.threadIdentifier = album.id.uuidString

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: remindAt
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        return UNNotificationRequest(
            identifier: notificationIdentifier(for: album),
            content: content,
            trigger: trigger
        )
    }
}