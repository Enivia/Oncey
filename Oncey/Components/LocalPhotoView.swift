//
//  LocalPhotoView.swift
//  Oncey
//

import SwiftUI

struct LocalPhotoView: View {
    let path: String?

    var body: some View {
        Group {
            if let path, let image = platformImage(for: path) {
                imageView(for: image)
            } else {
                placeholder
            }
        }
    }

#if os(iOS)
    private func platformImage(for path: String) -> UIImage? {
        ImageResourceService.platformImage(from: path)
    }

    private func imageView(for image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
    }
#elseif os(macOS)
    private func platformImage(for path: String) -> NSImage? {
        ImageResourceService.platformImage(from: path)
    }

    private func imageView(for image: NSImage) -> some View {
        Image(nsImage: image)
            .resizable()
            .scaledToFill()
    }
#endif

    private var placeholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.95, green: 0.89, blue: 0.74), Color(red: 0.79, green: 0.88, blue: 0.92)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
        }
    }
}