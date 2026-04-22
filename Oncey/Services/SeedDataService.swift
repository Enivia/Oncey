//
//  SeedDataService.swift
//  Oncey
//

import Foundation
import SwiftData

@MainActor
final class SeedDataService {
    func seedIfNeeded(in modelContext: ModelContext, bundle: Bundle = .main) throws {
        var descriptor = FetchDescriptor<Album>()
        descriptor.fetchLimit = 1

        if try !modelContext.fetch(descriptor).isEmpty {
            return
        }

        for seedAlbum in try seedAlbums(bundle: bundle) {
            modelContext.insert(seedAlbum.album)

            for moment in seedAlbum.moments {
                modelContext.insert(moment)
            }
        }

        try modelContext.save()
    }

    private func seedAlbums(bundle: Bundle) throws -> [SeedAlbumPayload] {
        let albumOneCreatedAt = makeDate(year: 2026, month: 4, day: 8, hour: 9, minute: 10)
        let albumOneMoments: [SeedMomentPayload] = [
            .init(
                photo: try ImageResourceService.samplePhotoPath(named: "sample-photo-1", bundle: bundle),
                location: "Kyoto, Japan",
                createdAt: makeDate(year: 2026, month: 4, day: 12, hour: 18, minute: 20)
            ),
            .init(
                photo: try ImageResourceService.samplePhotoPath(named: "sample-photo-2", bundle: bundle),
                location: "Kyoto, Japan",
                createdAt: makeDate(year: 2026, month: 4, day: 11, hour: 8, minute: 45)
            )
        ]

        let albumTwoCreatedAt = makeDate(year: 2026, month: 3, day: 22, hour: 14, minute: 30)
        let albumTwoMoments: [SeedMomentPayload] = [
            .init(
                photo: try ImageResourceService.samplePhotoPath(named: "sample-photo-3", bundle: bundle),
                location: "Copenhagen, Denmark",
                createdAt: makeDate(year: 2026, month: 4, day: 18, hour: 19, minute: 5)
            ),
            .init(
                photo: try ImageResourceService.samplePhotoPath(named: "sample-photo-4", bundle: bundle),
                location: "Copenhagen, Denmark",
                createdAt: makeDate(year: 2026, month: 4, day: 15, hour: 10, minute: 40)
            )
        ]

        return [
            buildAlbum(name: "Weekend Escape", createdAt: albumOneCreatedAt, moments: albumOneMoments),
            buildAlbum(name: "City Fragments", createdAt: albumTwoCreatedAt, moments: albumTwoMoments),
        ]
    }

    private func buildAlbum(name: String, createdAt: Date, moments payloads: [SeedMomentPayload]) -> SeedAlbumPayload {
        let updatedAt = payloads.map(\ .createdAt).max() ?? createdAt
        let album = Album(name: name, createdAt: createdAt, updatedAt: updatedAt)
        let moments = payloads.map {
            Moment(
                album: album,
                photo: $0.photo,
                location: $0.location,
                createdAt: $0.createdAt,
                updatedAt: $0.createdAt
            )
        }

        return SeedAlbumPayload(album: album, moments: moments)
    }

    private func makeDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute

        return components.date ?? .now
    }
}

private struct SeedAlbumPayload {
    let album: Album
    let moments: [Moment]
}

private struct SeedMomentPayload {
    let photo: String
    let location: String
    let createdAt: Date
}