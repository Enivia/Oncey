import Foundation
import SwiftData
import Testing
#if canImport(UIKit)
import UIKit
#endif
@testable import Oncey

struct OnceyTests {

    @Test func imageStorePersistsAndReplacesManagedFiles() throws {
        let originalPath = try AppImageStore.store(makeImage(color: .systemPink))
        defer { AppImageStore.deleteImageIfManaged(at: originalPath) }

        #expect(AppImageStore.isManagedPath(originalPath))
        #expect(FileManager.default.fileExists(atPath: originalPath))

        let replacedPath = try AppImageStore.replaceImage(at: originalPath, with: makeImage(color: .systemBlue))

        #expect(replacedPath == originalPath)
        #expect(FileManager.default.fileExists(atPath: replacedPath))
    }

    @Test func swiftDataCrudForAlbumsAndMoments() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let createdAt = Date(timeIntervalSince1970: 1_713_744_000)

        let album = Album(name: "Spring Trip", createdAt: createdAt, updatedAt: createdAt)
        let firstMoment = Moment(
            album: album,
            photo: "/tmp/first.jpg",
            location: "Kyoto, Japan",
            note: "First stop",
            createdAt: createdAt,
            updatedAt: createdAt
        )
        context.insert(album)
        context.insert(firstMoment)
        try context.save()

        let fetchedAlbums = try context.fetch(FetchDescriptor<Album>())
        #expect(fetchedAlbums.count == 1)
        #expect(fetchedAlbums.first?.moments.count == 1)
        #expect(fetchedAlbums.first?.moments.first?.note == "First stop")

        let secondMomentCreatedAt = createdAt.addingTimeInterval(3_600)
        let secondMoment = Moment(
            album: album,
            photo: "/tmp/second.jpg",
            location: "Kyoto, Japan",
            note: "Lantern street",
            createdAt: secondMomentCreatedAt,
            updatedAt: secondMomentCreatedAt
        )
        context.insert(secondMoment)
        try context.save()

        let fetchedMoments = try context.fetch(FetchDescriptor<Moment>())
        #expect(fetchedMoments.count == 2)
        #expect(album.updatedAt == createdAt)

        let originalCreatedAt = firstMoment.createdAt
        firstMoment.note = "Updated note"
        firstMoment.location = "Osaka, Japan"
        firstMoment.updatedAt = secondMomentCreatedAt
        try context.save()

        #expect(firstMoment.createdAt == originalCreatedAt)
        #expect(firstMoment.updatedAt == secondMomentCreatedAt)
        #expect(firstMoment.note == "Updated note")

        context.delete(album)
        try context.save()

        let remainingAlbums = try context.fetch(FetchDescriptor<Album>())
        let remainingMoments = try context.fetch(FetchDescriptor<Moment>())
        #expect(remainingAlbums.isEmpty)
        #expect(remainingMoments.isEmpty)
    }

#if canImport(UIKit)
    private func makeImage(color: UIColor) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 24, height: 24))
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 24, height: 24))
        }
    }
#endif

    private func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([Album.self, Moment.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

}
