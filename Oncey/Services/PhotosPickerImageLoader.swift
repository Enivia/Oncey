#if canImport(UIKit)
import Foundation
import ImageIO
import PhotosUI
import SwiftUI
import UIKit

enum PhotosPickerImageLoader {
    static let maximumPixelSize: CGFloat = 4_096

    static func loadImage(from item: PhotosPickerItem) async throws -> UIImage {
        guard let data = try await item.loadTransferable(type: Data.self) else {
            throw PhotosPickerImageLoaderError.loadFailed
        }

        return try decodeImage(from: data)
    }

    static func decodeImage(from data: Data, maximumPixelSize: CGFloat = maximumPixelSize) throws -> UIImage {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            throw PhotosPickerImageLoaderError.decodingFailed
        }

        let pixelLimit = max(Int(maximumPixelSize.rounded(.up)), 1)
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: pixelLimit
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            throw PhotosPickerImageLoaderError.decodingFailed
        }

        return UIImage(cgImage: cgImage)
    }
}

enum PhotosPickerImageLoaderError: LocalizedError {
    case loadFailed
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .loadFailed:
            return "Failed to load the selected image."
        case .decodingFailed:
            return "The selected image couldn't be decoded."
        }
    }
}
#endif