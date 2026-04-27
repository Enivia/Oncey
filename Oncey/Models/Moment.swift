//
//  Moment.swift
//  Oncey
//

import Foundation
import SwiftData

@Model
final class Moment {
    @Attribute(.unique) var id: UUID
    var albumId: UUID
    var photo: String
    var note: String
    var createdAt: Date
    var updatedAt: Date
    var album: Album?

    init(
        id: UUID = UUID(),
        album: Album,
        photo: String,
        note: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.albumId = album.id
        self.photo = photo
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.album = album
    }
}