//
//  AlbumTileView.swift
//  Oncey
//

import SwiftUI

struct AlbumTileView: View {
    let album: Album
    let coverPhotoPath: String?
    let reminderCountdownText: String?
    let momentCountText: String

    private static let layerTransforms: [CardLayerTransform] = [
        .init(x: -4, y: -4, angle: -1.8),
        .init(x: 5, y: 2, angle: 1.4),
        .init(x: -5, y: 3, angle: -1.0),
        .init(x: 6, y: -3, angle: 2.1),
        .init(x: -3, y: 2, angle: -1.5),
    ]

    private var displayedLayerCount: Int {
        max(1, min(album.moments.count, 5))
    }

    private var backdropTransforms: [CardLayerTransform] {
        Array(Self.layerTransforms.prefix(max(0, displayedLayerCount - 1)))
    }

    private var backdropBottomInset: CGFloat {
        backdropTransforms.map(\.y).max() ?? 0
    }

    var body: some View {
        ZStack(alignment: .top) {
            ForEach(Array(backdropTransforms.enumerated().reversed()), id: \.offset) { index, transform in
                Rectangle()
                    .fill(AppTheme.Colors.surface.opacity(1 - Double(index) * 0.08))
                    .rotationEffect(.degrees(transform.angle))
                    .offset(x: transform.x, y: transform.y)
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.s4) {
                coverImage

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
        .padding(.bottom, AppTheme.Spacing.s2 + backdropBottomInset)
        .overlay(alignment: .topTrailing) {
            if let reminderCountdownText {
                Text(reminderCountdownText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.accent)
                    .padding(.horizontal, AppTheme.Spacing.s3)
                    .padding(.vertical, AppTheme.Spacing.s2)
                    .glassEffect()
                    .padding(.trailing, AppTheme.Spacing.s8)
                    .padding(.top, AppTheme.Spacing.s8)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var coverImage: some View {
        GeometryReader { geometry in
            let containerSize = geometry.size

            ZStack {
                if coverPhotoPath != nil {
                  LocalPhotoView(path: coverPhotoPath)
                      .scaledToFill()
                      .frame(maxWidth: containerSize.width, maxHeight: containerSize.height)
                      .blur(radius: 20)
                      .clipped()
                }

                LocalPhotoView(path: coverPhotoPath)
                    .scaledToFit()
                    .frame(width: containerSize.width, height: containerSize.height)
            }
            .frame(width: containerSize.width, height: containerSize.height)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(4 / 3, contentMode: .fit)
    }

    private var resolvedCoverImageSize: CGSize? {
        guard let coverPhotoPath else {
            return nil
        }

        return ImageResourceService.imageSize(from: coverPhotoPath)
    }

    private var resolvedCoverPhotoOrientation: MomentPhotoOrientation {
        if let coverPhotoPath,
           let matchingMoment = album.moments.first(where: { $0.photo == coverPhotoPath }) {
            return matchingMoment.photoOrientation
        }

        let latestMoment = album.moments.max { lhs, rhs in
            if lhs.createdAt == rhs.createdAt {
                return lhs.updatedAt < rhs.updatedAt
            }

            return lhs.createdAt < rhs.createdAt
        }

        return latestMoment?.photoOrientation ?? .portrait
    }
}

private struct CardLayerTransform {
    let x: CGFloat
    let y: CGFloat
    let angle: Double
}

#Preview {
    let album: Album = {
        let album = Album(name: "Weekend Escape")
        let _ = Moment(album: album, photo: "", createdAt: .now.addingTimeInterval(-86_400 * 12))
        let _ = Moment(album: album, photo: "", createdAt: .now.addingTimeInterval(-86_400 * 2))
        return album
    }()

    AlbumTileView(
        album: album,
        coverPhotoPath: nil,
        reminderCountdownText: "4 days later",
        momentCountText: "2 Moments",
    )
        .padding()
        .background(AppTheme.Colors.background)
}
