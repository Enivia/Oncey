import Foundation
import SwiftData
import Testing
#if canImport(UIKit)
import UIKit
#endif
@testable import Oncey

struct AlbumDeletionServiceTests {
    @Test func deletingAlbumRemovesAlbumMomentsAndManagedAssets() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let createdAt = Date(timeIntervalSince1970: 1_713_744_000)
        let photoPath = try AppImageStore.store(makeImage(color: .systemGreen))
        let outlinePath = try AppImageStore.storeOutline(makeImage(color: .clear, strokeColor: .systemOrange))
        let photoURL = try resolvedLocalFileURL(for: photoPath)
        let outlineURL = try resolvedLocalFileURL(for: outlinePath)

        let album = Album(
            name: "Cleanup Album",
            templateOutlinePath: outlinePath,
            createdAt: createdAt,
            updatedAt: createdAt
        )
        let moment = Moment(
            album: album,
            photo: photoPath,
            note: "Delete me too",
            createdAt: createdAt,
            updatedAt: createdAt
        )

        context.insert(album)
        context.insert(moment)
        try context.save()

        try AlbumDeletionService.delete(album, in: context)

        let remainingAlbums = try context.fetch(FetchDescriptor<Album>())
        let remainingMoments = try context.fetch(FetchDescriptor<Moment>())

        #expect(remainingAlbums.isEmpty)
        #expect(remainingMoments.isEmpty)
        #expect(!FileManager.default.fileExists(atPath: photoURL.path(percentEncoded: false)))
        #expect(!FileManager.default.fileExists(atPath: outlineURL.path(percentEncoded: false)))
    }
}

#if canImport(UIKit)
private func makeImage(color: UIColor, strokeColor: UIColor? = nil) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 24, height: 24))
    return renderer.image { context in
        color.setFill()
        context.fill(CGRect(x: 0, y: 0, width: 24, height: 24))

        if let strokeColor {
            strokeColor.setStroke()
            context.cgContext.setLineWidth(2)
            context.cgContext.strokeEllipse(in: CGRect(x: 3, y: 3, width: 18, height: 18))
        }
    }
}
#endif

private func makeInMemoryContainer() throws -> ModelContainer {
    let schema = Schema([Album.self, Moment.self])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    return try ModelContainer(for: schema, configurations: [configuration])
}

private func resolvedLocalFileURL(for reference: String) throws -> URL {
    try #require(ImageResourceService.fileURL(for: reference))
}