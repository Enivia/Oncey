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
    var orientation: MomentPhotoOrientation?
    var remindValue: Int?
    var remindUnit: AlbumReminderUnit?
    var remindAt: Date?
    var createdAt: Date
    var updatedAt: Date
    @Relationship(deleteRule: .cascade, inverse: \Moment.album) var moments: [Moment]

    init(
        id: UUID = UUID(),
        name: String,
        orientation: MomentPhotoOrientation? = nil,
        remindValue: Int? = nil,
        remindUnit: AlbumReminderUnit? = nil,
        remindAt: Date? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        moments: [Moment] = []
    ) {
        self.id = id
        self.name = name
        self.orientation = orientation
        self.remindValue = remindValue
        self.remindUnit = remindUnit
        self.remindAt = remindAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.moments = moments
    }
}

extension Album {
    var earliestMomentForOrientation: Moment? {
        moments.min { lhs, rhs in
            if lhs.createdAt != rhs.createdAt {
                return lhs.createdAt < rhs.createdAt
            }

            return lhs.id.uuidString < rhs.id.uuidString
        }
    }

    @discardableResult
    func syncOrientation(
        imageSizeResolver: (String) -> CGSize? = ImageResourceService.imageSize(from:)
    ) -> MomentPhotoOrientation? {
        guard let earliestMomentForOrientation else {
            orientation = nil
            return nil
        }

        let resolvedOrientation = MomentPhotoOrientation.inferred(
            fromPhotoPath: earliestMomentForOrientation.photo,
            imageSizeResolver: imageSizeResolver
        )
        orientation = resolvedOrientation
        return orientation
    }

    var hasReminderConfiguration: Bool {
        remindValue != nil && remindUnit != nil
    }

    var hasReminder: Bool {
        hasReminderConfiguration && remindAt != nil
    }
}
