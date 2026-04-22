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
        guard !path.isEmpty else {
            return nil
        }

        return URL(fileURLWithPath: path)
    }

#if os(iOS)
    static func platformImage(from path: String) -> UIImage? {
        UIImage(contentsOfFile: path)
    }
#elseif os(macOS)
    static func platformImage(from path: String) -> NSImage? {
        NSImage(contentsOfFile: path)
    }
#endif
}