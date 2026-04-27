//
//  ImageResourceService.swift
//  Oncey
//

import Foundation
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

enum ImageResourceService {
    static func fileURL(for path: String) -> URL? {
        AppImageStore.fileURL(for: path)
    }

#if os(iOS)
    static func platformImage(from path: String) -> UIImage? {
        guard let resolvedPath = fileURL(for: path)?.path(percentEncoded: false) else {
            return nil
        }

        return UIImage(contentsOfFile: resolvedPath)
    }

    static func imageSize(from path: String) -> CGSize? {
        platformImage(from: path)?.size
    }
#elseif os(macOS)
    static func platformImage(from path: String) -> NSImage? {
        guard let resolvedPath = fileURL(for: path)?.path(percentEncoded: false) else {
            return nil
        }

        return NSImage(contentsOfFile: resolvedPath)
    }

    static func imageSize(from path: String) -> CGSize? {
        platformImage(from: path)?.size
    }
#endif
}