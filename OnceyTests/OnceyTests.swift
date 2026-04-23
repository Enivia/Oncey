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

    @Test func outlineStorePersistsAndReplacesManagedFiles() throws {
        let originalPath = try AppImageStore.storeOutline(makeImage(color: .clear, strokeColor: .systemYellow))
        defer { AppImageStore.deleteOutlineIfManaged(at: originalPath) }

        #expect(AppImageStore.isManagedPath(originalPath))
        #expect(FileManager.default.fileExists(atPath: originalPath))

        let replacedPath = try AppImageStore.replaceOutline(
            at: originalPath,
            with: makeImage(color: .clear, strokeColor: .systemRed)
        )

        #expect(replacedPath == originalPath)
        #expect(FileManager.default.fileExists(atPath: replacedPath))

        AppImageStore.deleteOutlineIfManaged(at: replacedPath)
        #expect(!FileManager.default.fileExists(atPath: replacedPath))
    }

    @MainActor
    @Test func outlineExtractionReturnsDraftWhenGeneratorSucceeds() async {
        let image = makeImage(color: .systemTeal)
        let outlineImage = makeImage(color: .clear, strokeColor: .white)

        let pipeline = PersonOutlineExtractionService.Pipeline(
            personInstance: { _, _ in outlineImage.cgImage },
            foregroundInstance: { _, _ in nil },
            personSegmentation: { _, _ in nil }
        )
        let draft = await PersonOutlineExtractionService.extract(from: image, pipeline: pipeline)

        let values = MainActor.assumeIsolated {
            (draft.hasOutline, draft.photoSize, draft.photoAspectRatio)
        }

        #expect(values.0)
        #expect(values.1 == image.size)
        #expect(values.2 == 1)
    }

    @MainActor
    @Test func outlineExtractionFallsBackWhenGeneratorThrows() async {
        struct ExtractionError: Error {}

        let image = makeImage(color: .systemMint)
        let outlineImage = makeImage(color: .clear, strokeColor: .systemBlue)
        let pipeline = PersonOutlineExtractionService.Pipeline(
            personInstance: { _, _ in throw ExtractionError() },
            foregroundInstance: { _, _ in outlineImage.cgImage },
            personSegmentation: { _, _ in nil }
        )
        let draft = await PersonOutlineExtractionService.extract(from: image, pipeline: pipeline)

        let values = MainActor.assumeIsolated {
            (draft.hasOutline, draft.outlineImage, draft.photoSize, draft.photoAspectRatio)
        }

        #expect(values.0)
        #expect(values.1 != nil)
        #expect(values.2 == image.size)
        #expect(values.3 == 1)
    }

    @Test func momentDeletionRemovesModelsAndManagedImages() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let createdAt = Date(timeIntervalSince1970: 1_713_744_000)
        let photoPath = try AppImageStore.store(makeImage(color: .systemGreen))

        let album = Album(name: "Cleanup Trip", createdAt: createdAt, updatedAt: createdAt)
        let moment = Moment(
            album: album,
            photo: photoPath,
            location: "Osaka, Japan",
            note: "Delete me",
            createdAt: createdAt,
            updatedAt: createdAt
        )

        context.insert(album)
        context.insert(moment)
        try context.save()

        try MomentDeletionService.delete([moment], in: context)

        let remainingMoments = try context.fetch(FetchDescriptor<Moment>())
        #expect(remainingMoments.isEmpty)
        #expect(!FileManager.default.fileExists(atPath: photoPath))
    }

    @MainActor
    @Test func shareExportCreatesImageFile() throws {
        let photoPath = try AppImageStore.store(makeImage(color: .systemOrange))
        defer { AppImageStore.deleteImageIfManaged(at: photoPath) }

        let album = Album(name: "Share Trip")
        let moment = Moment(
            album: album,
            photo: photoPath,
            location: "Kyoto, Japan",
            note: "Export this card",
            createdAt: Date(timeIntervalSince1970: 1_713_744_000),
            updatedAt: Date(timeIntervalSince1970: 1_713_744_000)
        )

        let exportURL = try MomentShareExportService.exportFile(moment: moment, style: .styledCard1, scale: 1)
        defer { try? FileManager.default.removeItem(at: exportURL) }

        #expect(FileManager.default.fileExists(atPath: exportURL.path()))

        let exportedAttributes = try FileManager.default.attributesOfItem(atPath: exportURL.path())
        let fileSize = exportedAttributes[.size] as? NSNumber
        #expect((fileSize?.intValue ?? 0) > 0)
    }

    @Test func swiftDataCrudForAlbumsAndMoments() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let createdAt = Date(timeIntervalSince1970: 1_713_744_000)

        let album = Album(
            name: "Spring Trip",
            templateOutlinePath: "/tmp/outline.png",
            templatePhotoWidth: 1_536,
            templatePhotoHeight: 1_024,
            createdAt: createdAt,
            updatedAt: createdAt
        )
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
        #expect(fetchedAlbums.first?.templateOutlinePath == "/tmp/outline.png")
        #expect(fetchedAlbums.first?.templatePhotoWidth == 1_536)
        #expect(fetchedAlbums.first?.templatePhotoHeight == 1_024)
        #expect(fetchedAlbums.first?.templatePhotoAspectRatio == 1.5)

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
        album.templateOutlinePath = "/tmp/outline-updated.png"
        album.templatePhotoWidth = 1_200
        album.templatePhotoHeight = 1_600
        try context.save()

        #expect(firstMoment.createdAt == originalCreatedAt)
        #expect(firstMoment.updatedAt == secondMomentCreatedAt)
        #expect(firstMoment.note == "Updated note")
        #expect(album.templateOutlinePath == "/tmp/outline-updated.png")
        #expect(album.templatePhotoAspectRatio == 0.75)

        context.delete(album)
        try context.save()

        let remainingAlbums = try context.fetch(FetchDescriptor<Album>())
        let remainingMoments = try context.fetch(FetchDescriptor<Moment>())
        #expect(remainingAlbums.isEmpty)
        #expect(remainingMoments.isEmpty)
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

}
