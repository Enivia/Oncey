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
    var templateOutlinePath: String?
    var templatePhotoWidth: Double?
    var templatePhotoHeight: Double?
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
        templateOutlinePath: String? = nil,
        templatePhotoWidth: Double? = nil,
        templatePhotoHeight: Double? = nil,
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
        self.templateOutlinePath = templateOutlinePath
        self.templatePhotoWidth = templatePhotoWidth
        self.templatePhotoHeight = templatePhotoHeight
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.moments = moments
    }
}

extension Album {
    var hasReminder: Bool {
        remindValue != nil && remindUnit != nil && remindAt != nil
    }

    var templatePhotoSize: CGSize? {
        guard let templatePhotoWidth, let templatePhotoHeight,
              templatePhotoWidth > 0, templatePhotoHeight > 0 else {
            return nil
        }

        return CGSize(width: templatePhotoWidth, height: templatePhotoHeight)
    }

    var templatePhotoAspectRatio: Double? {
        guard let templatePhotoSize, templatePhotoSize.height > 0 else {
            return nil
        }

        return templatePhotoSize.width / templatePhotoSize.height
    }
}