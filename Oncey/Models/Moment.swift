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
    var location: String
    var createdAt: Date
    var updatedAt: Date
    var album: Album?

    init(
        id: UUID = UUID(),
        album: Album,
        photo: String,
        location: String,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.albumId = album.id
        self.photo = photo
        self.location = location
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.album = album
    }
}