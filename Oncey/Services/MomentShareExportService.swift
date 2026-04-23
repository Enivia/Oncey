#if canImport(UIKit)
import Photos
import SwiftUI
import UIKit

@MainActor
enum MomentShareExportService {
    private static let exportDirectoryName = "MomentShareExports"
    private static let jpegCompressionQuality: CGFloat = 0.96
    private static let renderedCardWidth: CGFloat = 360

    static func renderImage(moment: Moment, style: MomentCardStyle, scale: CGFloat) throws -> UIImage {
        let renderer = ImageRenderer(
            content: MomentCardView(moment: moment, style: style, renderMode: .full)
                .frame(width: renderedCardWidth)
        )
        renderer.proposedSize = ProposedViewSize(width: renderedCardWidth, height: nil)
        renderer.scale = scale

        guard let image = renderer.uiImage else {
            throw MomentShareExportError.renderFailed
        }

        return image
    }

    static func exportFile(moment: Moment, style: MomentCardStyle, scale: CGFloat) throws -> URL {
        let image = try renderImage(moment: moment, style: style, scale: scale)
        guard let data = image.jpegData(compressionQuality: jpegCompressionQuality) else {
            throw MomentShareExportError.encodingFailed
        }

        let destinationURL = try exportURL(for: moment, style: style)
        try data.write(to: destinationURL, options: .atomic)
        return destinationURL
    }

    static func saveImageToPhotoLibrary(moment: Moment, style: MomentCardStyle, scale: CGFloat) async throws {
        let authorizationStatus = await resolvedPhotoLibraryAuthorizationStatus()
        guard authorizationStatus == .authorized || authorizationStatus == .limited else {
            throw MomentShareExportError.photoLibraryPermissionDenied
        }

        let image = try renderImage(moment: moment, style: style, scale: scale)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(throwing: MomentShareExportError.photoLibraryWriteFailed)
                }
            }
        }
    }

    private static func resolvedPhotoLibraryAuthorizationStatus() async -> PHAuthorizationStatus {
        let currentStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        if currentStatus == .notDetermined {
            return await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        }

        return currentStatus
    }

    private static func exportURL(for moment: Moment, style: MomentCardStyle) throws -> URL {
        let directoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(exportDirectoryName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: directoryURL.path()) {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }

        return directoryURL.appendingPathComponent("\(moment.id.uuidString)-\(style.rawValue)").appendingPathExtension("jpg")
    }
}

enum MomentShareExportError: LocalizedError {
    case renderFailed
    case encodingFailed
    case photoLibraryPermissionDenied
    case photoLibraryWriteFailed

    var errorDescription: String? {
        switch self {
        case .renderFailed:
            return "Failed to render the selected card style."
        case .encodingFailed:
            return "Failed to encode the rendered card image."
        case .photoLibraryPermissionDenied:
            return "Photo library access is required to save the rendered card."
        case .photoLibraryWriteFailed:
            return "The rendered card couldn't be saved to the photo library."
        }
    }
}
#endif
