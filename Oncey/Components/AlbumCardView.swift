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
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.primary.opacity(0.04 - Double(index) * 0.005))
                    .overlay {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                    }
                    .rotationEffect(.degrees(transform.angle))
                    .offset(x: transform.x, y: transform.y)
            }

            VStack(alignment: .leading, spacing: 14) {
                LocalPhotoView(path: coverPhotoPath)
                    .frame(maxWidth: .infinity)
                    .aspectRatio(4 / 3, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text(album.name)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(momentCountText)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(22)
            .background {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.background)
                    .shadow(color: .black.opacity(0.08), radius: 24, y: 10)
                    .overlay {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                    }
            }
        }
        .padding(.bottom, 18 + backdropBottomInset)
        .padding(.horizontal, 10)
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
        .background(Color(.systemGroupedBackground))
}