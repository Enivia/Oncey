//
//  ImageResourceService.swift
//  Oncey
//

import Foundation
import ImageIO
#if os(iOS)
import UIKit
typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit
typealias PlatformImage = NSImage
#endif

enum ImageResourceService {
    private static let imageCache = NSCache<NSString, PlatformImage>()
    private static let sizeCache = NSCache<NSString, ImageSizeBox>()

    static func fileURL(for path: String) -> URL? {
        AppImageStore.fileURL(for: path)
    }

    static func removeCachedResource(for path: String?) {
        guard let path else {
            return
        }

        imageCache.removeObject(forKey: path as NSString)
        sizeCache.removeObject(forKey: path as NSString)
    }

    static func primeImageCache(_ image: PlatformImage, for path: String) {
        cache(image, for: path)
    }

#if os(iOS)
    static func platformImage(from path: String) -> UIImage? {
        if let cachedImage = imageCache.object(forKey: path as NSString) {
            return cachedImage
        }

        guard let resolvedPath = fileURL(for: path)?.path(percentEncoded: false) else {
            return nil
        }

        guard let image = UIImage(contentsOfFile: resolvedPath) else {
            return nil
        }

        cache(image, for: path)
        return image
    }

    static func imageSize(from path: String) -> CGSize? {
        cachedSize(for: path) ?? metadataSize(for: path) ?? platformImage(from: path)?.size
    }
#elseif os(macOS)
    static func platformImage(from path: String) -> NSImage? {
        if let cachedImage = imageCache.object(forKey: path as NSString) {
            return cachedImage
        }

        guard let resolvedPath = fileURL(for: path)?.path(percentEncoded: false) else {
            return nil
        }

        guard let image = NSImage(contentsOfFile: resolvedPath) else {
            return nil
        }

        cache(image, for: path)
        return image
    }

    static func imageSize(from path: String) -> CGSize? {
        cachedSize(for: path) ?? metadataSize(for: path) ?? platformImage(from: path)?.size
    }
#endif

    private static func cache(_ image: PlatformImage, for path: String) {
        imageCache.setObject(image, forKey: path as NSString)
        cache(size: image.size, for: path)
    }

    private static func cachedSize(for path: String) -> CGSize? {
        sizeCache.object(forKey: path as NSString)?.size
    }

    @discardableResult
    private static func cache(size: CGSize, for path: String) -> CGSize {
        sizeCache.setObject(ImageSizeBox(size: size), forKey: path as NSString)
        return size
    }

    private static func metadataSize(for path: String) -> CGSize? {
        guard let url = fileURL(for: path) else {
            return nil
        }

        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let pixelWidth = (properties[kCGImagePropertyPixelWidth] as? NSNumber)?.doubleValue,
              let pixelHeight = (properties[kCGImagePropertyPixelHeight] as? NSNumber)?.doubleValue else {
            return nil
        }

        let orientation = (properties[kCGImagePropertyOrientation] as? NSNumber)?.intValue ?? 1
        let size = if [5, 6, 7, 8].contains(orientation) {
            CGSize(width: pixelHeight, height: pixelWidth)
        } else {
            CGSize(width: pixelWidth, height: pixelHeight)
        }

        return cache(size: size, for: path)
    }
}

private final class ImageSizeBox {
    let size: CGSize

    init(size: CGSize) {
        self.size = size
    }
}