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
    static func samplePhotoPath(named name: String, bundle: Bundle = .main) throws -> String {
        guard let url = bundle.url(forResource: name, withExtension: "png") else {
            throw ImageResourceError.missingResource(name)
        }

        return url.path()
    }

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

enum ImageResourceError: LocalizedError {
    case missingResource(String)

    var errorDescription: String? {
        switch self {
        case .missingResource(let name):
            "Missing bundled image resource: \(name).png"
        }
    }
}