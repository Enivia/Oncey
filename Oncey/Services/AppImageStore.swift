import Foundation
#if canImport(UIKit)
import UIKit

enum AppImageStore {
    private static let photoDirectoryName = "MomentPhotos"
    private static let outlineDirectoryName = "AlbumTemplateOutlines"
    private static let jpegCompressionQuality: CGFloat = 0.92

    static func store(_ image: UIImage) throws -> String {
        let destinationURL = try storageDirectory(named: photoDirectoryName)
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("jpg")

        try write(image, to: destinationURL)
        return fileSystemPath(for: destinationURL)
    }

    static func storeOutline(_ image: UIImage) throws -> String {
        let destinationURL = try storageDirectory(named: outlineDirectoryName)
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("png")

        try writeOutline(image, to: destinationURL)
        return fileSystemPath(for: destinationURL)
    }

    static func replaceOutline(at existingPath: String?, with image: UIImage) throws -> String {
        if let existingPath, isManagedPath(existingPath, in: outlineDirectoryName) {
            let destinationURL = URL(fileURLWithPath: existingPath)
            try writeOutline(image, to: destinationURL)
            return fileSystemPath(for: destinationURL)
        }

        return try storeOutline(image)
    }

    static func replaceImage(at existingPath: String?, with image: UIImage) throws -> String {
        if let existingPath, isManagedPath(existingPath, in: photoDirectoryName) {
            let destinationURL = URL(fileURLWithPath: existingPath)
            try write(image, to: destinationURL)
            return fileSystemPath(for: destinationURL)
        }

        return try store(image)
    }

    static func deleteImageIfManaged(at path: String?) {
        guard let path, isManagedPath(path, in: photoDirectoryName) else {
            return
        }

        try? FileManager.default.removeItem(at: URL(fileURLWithPath: path))
    }

    static func deleteOutlineIfManaged(at path: String?) {
        guard let path, isManagedPath(path, in: outlineDirectoryName) else {
            return
        }

        try? FileManager.default.removeItem(at: URL(fileURLWithPath: path))
    }

    static func isManagedPath(_ path: String) -> Bool {
        isManagedPath(path, in: photoDirectoryName) || isManagedPath(path, in: outlineDirectoryName)
    }

    private static func isManagedPath(_ path: String, in directoryName: String) -> Bool {
        guard let directoryPath = try? fileSystemPath(for: storageDirectory(named: directoryName)) else {
            return false
        }

        let standardizedPath = fileSystemPath(for: URL(fileURLWithPath: path))
        return standardizedPath.hasPrefix(directoryPath)
    }

    private static func storageDirectory(named directoryName: String) throws -> URL {
        let baseDirectory = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = baseDirectory.appendingPathComponent(directoryName, isDirectory: true)

        if !FileManager.default.fileExists(atPath: directory.path()) {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        return directory
    }

    private static func write(_ image: UIImage, to url: URL) throws {
        guard let data = normalized(image).jpegData(compressionQuality: jpegCompressionQuality) else {
            throw AppImageStoreError.encodingFailed
        }

        try data.write(to: url, options: .atomic)
    }

    private static func writeOutline(_ image: UIImage, to url: URL) throws {
        guard let data = normalized(image).pngData() else {
            throw AppImageStoreError.encodingFailed
        }

        try data.write(to: url, options: .atomic)
    }

    private static func fileSystemPath(for url: URL) -> String {
        url.standardizedFileURL.path(percentEncoded: false)
    }

    private static func normalized(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else {
            return image
        }

        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }
}

enum AppImageStoreError: LocalizedError {
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode image data for storage."
        }
    }
}
#endif