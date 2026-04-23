//
//  AlbumCardView.swift
//  Oncey
//

import SwiftUI

struct AlbumCardView: View {
    let album: Album
    let coverPhotoPath: String?
    let momentCountText: String
    let layerCount: Int

    private static let layerTransforms: [CardLayerTransform] = [
        .init(x: -10, y: 10, angle: -1.8),
        .init(x: 8, y: 8, angle: 1.4),
        .init(x: -5, y: 3, angle: -1.0),
        .init(x: 6, y: 8, angle: 2.1),
        .init(x: -8, y: 6, angle: -1.5),
    ]

    private var displayedLayerCount: Int {
        max(1, min(layerCount, 5))
    }

    private var backdropTransforms: [CardLayerTransform] {
        Array(Self.layerTransforms.prefix(max(0, displayedLayerCount - 1)))
    }

    private var backdropBottomInset: CGFloat {
        backdropTransforms.map(\ .y).max() ?? 0
    }

    var body: some View {
        ZStack(alignment: .top) {
            ForEach(Array(backdropTransforms.enumerated().reversed()), id: \.offset) { index, transform in
                Rectangle()
                    .fill(AppTheme.Colors.surface.opacity(0.78 - Double(index) * 0.08))
                    .border(AppTheme.Colors.border.opacity(0.75))
                    .rotationEffect(.degrees(transform.angle))
                    .offset(x: transform.x, y: transform.y)
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.s4) {
                LocalPhotoView(path: coverPhotoPath)
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fit)
                    .clipped()

                VStack(alignment: .leading, spacing: AppTheme.Spacing.s2) {
                    Text(album.name)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                        .lineLimit(1)

                    Text(momentCountText)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .lineLimit(1)
                }
            }
            .padding(AppTheme.Spacing.s6)
            .background {
                Rectangle()
                    .fill(AppTheme.Colors.surface)
                    .border(AppTheme.Colors.border)
                    .shadow(color: AppTheme.Colors.shadow, radius: AppTheme.Shadow.cardRadius, y: AppTheme.Shadow.cardYOffset)
            }
        }
        .padding(.bottom, AppTheme.Spacing.s6 + backdropBottomInset)
    }
}

private struct CardLayerTransform {
    let x: CGFloat
    let y: CGFloat
    let angle: Double
}

#Preview {
    let album = Album(name: "Weekend Escape")

    AlbumCardView(album: album, coverPhotoPath: nil, momentCountText: "2 Moments", layerCount: 2)
        .padding()
    .background(AppTheme.Colors.background)
}
