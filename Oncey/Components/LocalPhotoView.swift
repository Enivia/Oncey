//
//  LocalPhotoView.swift
//  Oncey
//

import SwiftUI

struct LocalPhotoView: View {
    let path: String?

    var body: some View {
        if let path, let image = platformImage(for: path) {
            Image(uiImage: image).resizable()
        } else {
            placeholder
        }
    }

    private func platformImage(for path: String) -> UIImage? {
        ImageResourceService.platformImage(from: path)
    }

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
