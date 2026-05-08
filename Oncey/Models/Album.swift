//
//  Album.swift
//  Oncey
//

import CoreGraphics
import Foundation
import SwiftData

@Model
final class Album {
    @Attribute(.unique) var id: UUID
    var name: String
    var ratio: CameraCaptureAspect?
    var remindValue: Int?
    var remindUnit: AlbumReminderUnit?
    var remindAt: Date?
    var createdAt: Date
    var updatedAt: Date
    @Relationship(deleteRule: .cascade, inverse: \Moment.album) var moments: [Moment]

    init(
        id: UUID = UUID(),
        name: String,
        ratio: CameraCaptureAspect? = nil,
        remindValue: Int? = nil,
        remindUnit: AlbumReminderUnit? = nil,
        remindAt: Date? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        moments: [Moment] = []
    ) {
        self.id = id
        self.name = name
        self.ratio = ratio
        self.remindValue = remindValue
        self.remindUnit = remindUnit
        self.remindAt = remindAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.moments = moments
    }
}

extension Album {
    var hasReminderConfiguration: Bool {
        remindValue != nil && remindUnit != nil
    }

    var hasReminder: Bool {
        hasReminderConfiguration && remindAt != nil
    }
}
