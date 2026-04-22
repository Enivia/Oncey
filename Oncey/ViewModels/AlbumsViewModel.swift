//
//  AlbumsViewModel.swift
//  Oncey
//

import Observation
import Foundation

@MainActor
@Observable
final class AlbumsViewModel {
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
}