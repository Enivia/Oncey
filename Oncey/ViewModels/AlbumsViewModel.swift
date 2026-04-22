//
//  AlbumsViewModel.swift
//  Oncey
//

import Observation
import Foundation
import SwiftData

@MainActor
@Observable
final class AlbumsViewModel {
    private let seedDataService = SeedDataService()

    var hasAttemptedSeed = false

    func seedIfNeeded(in modelContext: ModelContext) {
        guard !hasAttemptedSeed else {
            return
        }

        hasAttemptedSeed = true

        do {
            try seedDataService.seedIfNeeded(in: modelContext)
        } catch {
            assertionFailure("Failed to seed sample data: \(error.localizedDescription)")
        }
    }

    func coverPhotoPath(for album: Album) -> String? {
        album.moments
            .sorted { $0.createdAt > $1.createdAt }
            .first?
            .photo
    }

    func momentCountText(for album: Album) -> String {
        let count = album.moments.count
        return count == 1 ? "1 Moment" : "\(count) Moments"
    }
}