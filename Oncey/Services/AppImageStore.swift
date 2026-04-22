import Foundation
#if canImport(UIKit)
import UIKit

enum AppImageStore {
    private static let directoryName = "MomentPhotos"
    private static let jpegCompressionQuality: CGFloat = 0.92

    static func store(_ image: UIImage) throws -> String {
        let destinationURL = try storageDirectory()
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("jpg")

        try write(image, to: destinationURL)
        return fileSystemPath(for: destinationURL)
    }

    static func replaceImage(at existingPath: String?, with image: UIImage) throws -> String {
        if let existingPath, isManagedPath(existingPath) {
            let destinationURL = URL(fileURLWithPath: existingPath)
            try write(image, to: destinationURL)
            return fileSystemPath(for: destinationURL)
        }

        return try store(image)
    }

    static func deleteImageIfManaged(at path: String?) {
        guard let path, isManagedPath(path) else {
            return
        }

        try? FileManager.default.removeItem(at: URL(fileURLWithPath: path))
    }

    static func isManagedPath(_ path: String) -> Bool {
        guard let directoryPath = try? fileSystemPath(for: storageDirectory()) else {
            return false
        }

        let standardizedPath = fileSystemPath(for: URL(fileURLWithPath: path))
        return standardizedPath.hasPrefix(directoryPath)
    }

    private static func storageDirectory() throws -> URL {
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