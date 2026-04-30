//
//  LocalPhotoView.swift
//  Oncey
//

import SwiftUI

struct LocalPhotoView: View {
    let path: String?
    var contentMode: ContentMode = .fill

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

    @ViewBuilder
    private func imageView(for image: UIImage) -> some View {
        switch contentMode {
        case .fill:
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        case .fit:
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        }
    }
#elseif os(macOS)
    private func platformImage(for path: String) -> NSImage? {
        ImageResourceService.platformImage(from: path)
    }

    @ViewBuilder
    private func imageView(for image: NSImage) -> some View {
        switch contentMode {
        case .fill:
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
        case .fit:
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
        }
    }
#endif

    private var placeholder: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.Colors.accentSoft, AppTheme.Colors.secondarySoft],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 36, weight: .medium))
                .foregroundStyle(.white)
        }
    }
}

#Preview("Placeholder") {
    LocalPhotoView(path: nil)
        .frame(width: 320, height: 240)
        .padding()
        .background(AppTheme.Colors.background)
}
