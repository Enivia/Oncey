//
//  AlbumTileView.swift
//  Oncey
//

import SwiftUI

struct AlbumTileView: View {
    let album: Album
    let coverPhotoPath: String?
    let albumCreatedText: String
    let momentCountText: String
    let reminderCountdownText: String?
    let displayedMomentNodeCount: Int
    let showsReminderNode: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            coverImage

            VStack(alignment: .leading, spacing: 0){
                Text(album.name)
                    .font(.title3.weight(.semibold))
                    .lineLimit(1)

                AlbumTimelineSummaryView(
                    momentNodeCount: displayedMomentNodeCount,
                    showsReminderNode: showsReminderNode
                )
                .padding(.top, AppTheme.Spacing.s4)

                HStack(alignment: .center) {
                    Text(albumCreatedText)
                        .font(.footnote.weight(.light))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .lineLimit(1)
                    
                    Spacer(minLength: AppTheme.Spacing.s4)

                    Text(momentCountText)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(AppTheme.Colors.accent)
                        .lineLimit(1)
                }
                .padding(.top, AppTheme.Spacing.s2)
            }
            .padding(AppTheme.Spacing.s5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous)
                .fill(AppTheme.Colors.surface)
                .shadow(color: AppTheme.Colors.shadow, radius: AppTheme.Shadow.softRadius, y: AppTheme.Shadow.softYOffset)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous))
        .overlay(alignment: .topTrailing) {
            if let reminderCountdownText {
                Text(reminderCountdownText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.accent)
                    .padding(.horizontal, AppTheme.Spacing.s3)
                    .padding(.vertical, AppTheme.Spacing.s2)
                    .glassEffect()
                    .padding(.trailing, 12)
                    .padding(.top, 12)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var coverImage: some View {
        GeometryReader { geometry in
            let containerSize = geometry.size
            let fittedImageSize = AlbumCardCoverLayout.fittedImageSize(
                for: resolvedCoverSourceSize,
                in: containerSize
            )

            ZStack {
                LocalPhotoView(path: coverPhotoPath)
                    .frame(width: containerSize.width, height: containerSize.height)
                    .blur(radius: coverPhotoPath == nil ? 0 : 20)
                    .scaleEffect(coverPhotoPath == nil ? 1 : 1.06)
                    .clipped()

                LocalPhotoView(path: coverPhotoPath, contentMode: .fit)
                    .frame(width: fittedImageSize.width, height: fittedImageSize.height)
            }
            .frame(width: containerSize.width, height: containerSize.height)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(4 / 3, contentMode: .fit)
    }

    private var resolvedCoverSourceSize: CGSize {
        guard let coverPhotoPath,
              let imageSize = ImageResourceService.imageSize(from: coverPhotoPath),
              imageSize.width > 0,
              imageSize.height > 0 else {
            return CGSize(width: 4, height: 3)
        }

        return imageSize
    }
}

private struct AlbumTimelineSummaryView: View {
    let momentNodeCount: Int
    let showsReminderNode: Bool

    private let maxNodeSlotCount = 7

    private var nodeStyles: [AlbumTimelineNodeStyle] {
        let momentNodes = Array(repeating: AlbumTimelineNodeStyle.moment, count: momentNodeCount)
        if showsReminderNode {
            return momentNodes + [.reminder]
        }

        return momentNodes
    }

    var body: some View {
        GeometryReader { geometry in
            let lineY = geometry.size.height / 2
            let nodeDiameter: CGFloat = 12
            let nodeRadius = nodeDiameter / 2
            let lineStartX = nodeRadius
            let lineEndX = max(lineStartX, geometry.size.width - nodeRadius)
            let displayedNodeStyles = Array(nodeStyles.prefix(maxNodeSlotCount))
            let stepCount = max(maxNodeSlotCount - 1, 1)
            let usableWidth = max(0, lineEndX - lineStartX - 32)

            ZStack {
                Path { path in
                    path.move(to: CGPoint(x: lineStartX, y: lineY))
                    path.addLine(to: CGPoint(x: lineEndX, y: lineY))
                }
                .stroke(
                    AppTheme.Colors.accent ,
                    style: StrokeStyle(lineWidth: 0.6, lineCap: .round, dash: [4, 4])
                )

                ForEach(Array(displayedNodeStyles.enumerated()), id: \.offset) { index, style in
                    let progress = CGFloat(index) / CGFloat(stepCount)
                    AlbumTimelineNodeView(style: style)
                        .position(
                            x: lineStartX + usableWidth * progress,
                            y: lineY
                        )
                }
            }
        }
        .frame(height: 16)
    }
}

private struct AlbumTimelineNodeView: View {
    let style: AlbumTimelineNodeStyle

    var body: some View {
        Circle()
            .fill(fillColor)
            .frame(width: 6, height: 6)
            .overlay {
                Circle()
                    .stroke(strokeColor, style: strokeStyle)
            }
    }

    private var fillColor: Color {
        switch style {
        case .moment:
            return AppTheme.Colors.accentSoft
        case .reminder:
            return AppTheme.Colors.surface
        }
    }

    private var strokeColor: Color {
        switch style {
        case .moment:
            return AppTheme.Colors.accent
        case .reminder:
            return AppTheme.Colors.accent
        }
    }

    private var strokeStyle: StrokeStyle {
        switch style {
        case .moment:
            return StrokeStyle(lineWidth: 1)
        case .reminder:
            return StrokeStyle(lineWidth: 1, dash: [3, 1.5])
        }
    }
}

private enum AlbumTimelineNodeStyle {
    case moment
    case reminder
}

#Preview {
    let album: Album = {
        let album = Album(name: "Weekend Escape")
        let _ = Moment(album: album, photo: "", createdAt: .now.addingTimeInterval(-86_400 * 12))
        let _ = Moment(album: album, photo: "", createdAt: .now.addingTimeInterval(-86_400 * 2))
        album.remindValue = 1
        album.remindUnit = .week
        album.remindAt = .now.addingTimeInterval(86_400 * 4)
        return album
    }()

    AlbumTileView(
        album: album,
        coverPhotoPath: nil,
        albumCreatedText: "Apr 13, 2026",
        momentCountText: "2 Moments",
        reminderCountdownText: "4 days later",
        displayedMomentNodeCount: 2,
        showsReminderNode: true
    )
        .padding()
        .background(AppTheme.Colors.background)
}
