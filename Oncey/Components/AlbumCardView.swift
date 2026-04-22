//
//  AlbumCardView.swift
//  Oncey
//

import SwiftUI

struct AlbumCardView: View {
    let album: Album
    let coverPhotoPath: String?
    let momentCountText: String

    private let layerTransforms: [CardLayerTransform] = [
        .init(x: -10, y: 12, angle: -2.0),
        .init(x: 8, y: 10, angle: 1.5),
        .init(x: -4, y: 4, angle: -1.0),
    ]

    var body: some View {
        ZStack(alignment: .top) {
            ForEach(Array(layerTransforms.enumerated()), id: \.offset) { index, transform in
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.primary.opacity(0.05 - Double(index) * 0.01))
                    .overlay {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                    }
                    .rotationEffect(.degrees(transform.angle))
                    .offset(x: transform.x, y: transform.y)
            }

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.08), radius: 24, y: 10)
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                }
                .overlay {
                    VStack(alignment: .leading, spacing: 14) {
                        LocalPhotoView(path: coverPhotoPath)
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .aspectRatio(4 / 3, contentMode: .fit)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(album.name)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)

                            Text(momentCountText)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(22)
                }
        }
        .padding(.bottom, 18)
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

    AlbumCardView(album: album, coverPhotoPath: nil, momentCountText: "2 Moments")
        .padding()
        .background(Color(.systemGroupedBackground))
}