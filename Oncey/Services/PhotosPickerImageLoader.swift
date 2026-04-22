#if canImport(UIKit)
import Foundation
import PhotosUI
import SwiftUI
import UIKit

enum PhotosPickerImageLoader {
    static func loadImage(from item: PhotosPickerItem) async throws -> UIImage {
        guard let data = try await item.loadTransferable(type: Data.self) else {
            throw PhotosPickerImageLoaderError.loadFailed
        }

        guard let image = UIImage(data: data) else {
            throw PhotosPickerImageLoaderError.decodingFailed
        }

        return image
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