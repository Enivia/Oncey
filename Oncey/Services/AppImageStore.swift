import Foundation
#if canImport(UIKit)
import UIKit
#endif

enum AppImageStore {
    private static let photoDirectoryName = "MomentPhotos"
    private static let outlineDirectoryName = "AlbumTemplateOutlines"
    private static let managedReferenceScheme = "oncey-managed"
#if canImport(UIKit)
    private static let jpegCompressionQuality: CGFloat = 0.92

    static func store(_ image: UIImage) throws -> String {
        let destinationURL = try storageDirectory(named: photoDirectoryName)
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("jpg")

        try write(image, to: destinationURL)
        return managedReference(for: destinationURL, in: photoDirectoryName)
    }

    static func storeOutline(_ image: UIImage) throws -> String {
        let destinationURL = try storageDirectory(named: outlineDirectoryName)
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("png")

        try writeOutline(image, to: destinationURL)
        return managedReference(for: destinationURL, in: outlineDirectoryName)
    }

    static func replaceOutline(at existingPath: String?, with image: UIImage) throws -> String {
        if let existingPath, let destinationURL = managedFileURL(for: existingPath, in: outlineDirectoryName) {
            try writeOutline(image, to: destinationURL)
            return managedReference(for: destinationURL, in: outlineDirectoryName)
        }

        return try storeOutline(image)
    }

    static func replaceImage(at existingPath: String?, with image: UIImage) throws -> String {
        if let existingPath, let destinationURL = managedFileURL(for: existingPath, in: photoDirectoryName) {
            try write(image, to: destinationURL)
            return managedReference(for: destinationURL, in: photoDirectoryName)
        }

        return try store(image)
    }
#endif

    static func fileURL(for reference: String) -> URL? {
        guard !reference.isEmpty else {
            return nil
        }

        if let managedURL = managedFileURL(for: reference) {
            return managedURL
        }

        guard reference.hasPrefix("/") else {
            return nil
        }

        return URL(fileURLWithPath: reference).standardizedFileURL
    }

    static func deleteImageIfManaged(at path: String?) {
        guard let path, let destinationURL = managedFileURL(for: path, in: photoDirectoryName) else {
            return
        }

        try? FileManager.default.removeItem(at: destinationURL)
    }

    static func deleteOutlineIfManaged(at path: String?) {
        guard let path, let destinationURL = managedFileURL(for: path, in: outlineDirectoryName) else {
            return
        }

        try? FileManager.default.removeItem(at: destinationURL)
    }

    static func isManagedPath(_ path: String) -> Bool {
        managedLocation(for: path) != nil
    }

    private static func managedFileURL(for reference: String) -> URL? {
        guard let location = managedLocation(for: reference) else {
            return nil
        }

        return try? storageDirectory(named: location.directoryName)
            .appendingPathComponent(location.fileName)
    }

    private static func managedFileURL(for reference: String, in directoryName: String) -> URL? {
        guard let location = managedLocation(for: reference), location.directoryName == directoryName else {
            return nil
        }

        return try? storageDirectory(named: directoryName)
            .appendingPathComponent(location.fileName)
    }

    private static func managedLocation(for reference: String) -> ManagedLocation? {
        guard !reference.isEmpty else {
            return nil
        }

        if let location = managedReferenceLocation(for: reference) {
            return location
        }

        return legacyManagedLocation(for: reference)
    }

    private static func managedReferenceLocation(for reference: String) -> ManagedLocation? {
        guard let url = URL(string: reference),
              url.scheme == managedReferenceScheme,
              let directoryName = url.host,
              isManagedDirectory(directoryName) else {
            return nil
        }

        return sanitizedManagedLocation(directoryName: directoryName, fileName: url.lastPathComponent)
    }

    private static func legacyManagedLocation(for path: String) -> ManagedLocation? {
        let standardizedPath = URL(fileURLWithPath: path).standardizedFileURL.path(percentEncoded: false)

        for directoryName in [photoDirectoryName, outlineDirectoryName] {
            let marker = "/\(directoryName)/"
            guard let markerRange = standardizedPath.range(of: marker, options: .backwards) else {
                continue
            }

            let fileName = String(standardizedPath[markerRange.upperBound...])
            if let location = sanitizedManagedLocation(directoryName: directoryName, fileName: fileName) {
                return location
            }
        }

        return nil
    }

    private static func sanitizedManagedLocation(directoryName: String, fileName: String) -> ManagedLocation? {
        guard isManagedDirectory(directoryName),
              !fileName.isEmpty,
              !fileName.contains("/"),
              !fileName.contains("..") else {
            return nil
        }

        return ManagedLocation(directoryName: directoryName, fileName: fileName)
    }

    private static func isManagedDirectory(_ directoryName: String) -> Bool {
        directoryName == photoDirectoryName || directoryName == outlineDirectoryName
    }

    private static func managedReference(for url: URL, in directoryName: String) -> String {
        "\(managedReferenceScheme)://\(directoryName)/\(url.lastPathComponent)"
    }

    private struct ManagedLocation {
        let directoryName: String
        let fileName: String
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

#if canImport(UIKit)
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

    private static func normalized(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else {
            return image
        }

        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }
#endif
}

#if canImport(UIKit)
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