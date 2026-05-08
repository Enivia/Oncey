import Foundation
import SwiftData
import Testing
#if canImport(UIKit)
import UIKit
#endif
@testable import Oncey

struct MomentDeletionServiceTests {
    @Test func deletingOnlyMomentClearsAlbumOrientation() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let createdAt = Date(timeIntervalSince1970: 1_713_744_000)
        let photoPath = try AppImageStore.store(makeImage(size: CGSize(width: 24, height: 32), color: .systemBlue))

        let album = Album(
            name: "Cleanup Album",
            orientation: .portrait,
            createdAt: createdAt,
            updatedAt: createdAt
        )
        let moment = Moment(
            album: album,
            photo: photoPath,
            note: "Only moment",
            createdAt: createdAt,
            updatedAt: createdAt
        )

        context.insert(album)
        context.insert(moment)
        try context.save()

        try MomentDeletionService.delete([moment], in: context, updatedAt: createdAt.addingTimeInterval(60))

        #expect(album.orientation == nil)
        #expect(album.updatedAt == createdAt.addingTimeInterval(60))
    }

    @Test func deletingEarliestMomentRecomputesAlbumOrientationFromNextEarliestMoment() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let firstCreatedAt = Date(timeIntervalSince1970: 1_713_744_000)
        let secondCreatedAt = firstCreatedAt.addingTimeInterval(60)
        let updatedAt = secondCreatedAt.addingTimeInterval(60)
        let portraitPath = try AppImageStore.store(makeImage(size: CGSize(width: 24, height: 32), color: .systemPink))
        let landscapePath = try AppImageStore.store(makeImage(size: CGSize(width: 32, height: 24), color: .systemGreen))

        let album = Album(
            name: "Trip",
            orientation: .portrait,
            createdAt: firstCreatedAt,
            updatedAt: firstCreatedAt
        )
        let earliestMoment = Moment(
            album: album,
            photo: portraitPath,
            note: "Earliest",
            createdAt: firstCreatedAt,
            updatedAt: firstCreatedAt
        )
        let nextMoment = Moment(
            album: album,
            photo: landscapePath,
            note: "Next",
            createdAt: secondCreatedAt,
            updatedAt: secondCreatedAt
        )

        context.insert(album)
        context.insert(earliestMoment)
        context.insert(nextMoment)
        try context.save()

        try MomentDeletionService.delete([earliestMoment], in: context, updatedAt: updatedAt)

        #expect(album.orientation == .landscape)
        #expect(album.updatedAt == updatedAt)
    }

    @Test func deletingMomentClearsOrientationWhenRemainingImageSizeCannotBeResolved() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let firstCreatedAt = Date(timeIntervalSince1970: 1_713_744_000)
        let secondCreatedAt = firstCreatedAt.addingTimeInterval(60)
        let updatedAt = secondCreatedAt.addingTimeInterval(60)
        let portraitPath = try AppImageStore.store(makeImage(size: CGSize(width: 24, height: 32), color: .systemBlue))

        let album = Album(
            name: "Trip",
            orientation: .landscape,
            createdAt: firstCreatedAt,
            updatedAt: firstCreatedAt
        )
        let earliestMoment = Moment(
            album: album,
            photo: portraitPath,
            note: "Earliest",
            createdAt: firstCreatedAt,
            updatedAt: firstCreatedAt
        )
        let unresolvedMoment = Moment(
            album: album,
            photo: "/tmp/nonexistent-moment.jpg",
            note: "Remaining",
            createdAt: secondCreatedAt,
            updatedAt: secondCreatedAt
        )

        context.insert(album)
        context.insert(earliestMoment)
        context.insert(unresolvedMoment)
        try context.save()

        try MomentDeletionService.delete([earliestMoment], in: context, updatedAt: updatedAt)

        #expect(album.orientation == nil)
        #expect(album.updatedAt == updatedAt)
    }
}

#if canImport(UIKit)
private func makeImage(size: CGSize, color: UIColor) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { context in
        color.setFill()
        context.fill(CGRect(origin: .zero, size: size))
    }
}
#endif

private func makeInMemoryContainer() throws -> ModelContainer {
    let schema = Schema([Album.self, Moment.self])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    return try ModelContainer(for: schema, configurations: [configuration])
}