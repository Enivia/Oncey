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
    let latestMomentCreatedText: String?
    let reminderCountdownText: String?
    let displayedMomentNodeCount: Int
    let showsReminderNode: Bool

    private static let layerTransforms: [CardLayerTransform] = [
        .init(x: -20, y: 4, angle: -1.8),
        .init(x: 15, y: 4, angle: 1.4),
        .init(x: -12, y: 6, angle: -1.0),
        .init(x: 25, y: 2, angle: 2.1),
        .init(x: -5, y: 6, angle: -1.5),
    ]

    private var displayedLayerCount: Int {
        max(1, min(layerCount, 5))
    }

    private var backdropTransforms: [CardLayerTransform] {
        Array(Self.layerTransforms.prefix(max(0, displayedLayerCount - 1)))
    }

    private var backdropBottomInset: CGFloat {
        backdropTransforms.map(\.y).max() ?? 0
    }

    private var backdropLeadingInset: CGFloat {
        abs(min(0, backdropTransforms.map(\.x).min() ?? 0))
    }

    private var backdropTrailingInset: CGFloat {
        max(0, backdropTransforms.map(\.x).max() ?? 0)
    }

    private var imageSide: CGFloat {
        min(max(AppTheme.Layout.screenWidth * 0.28, 108), 140)
    }

    private var summaryAccentColor: Color {
        Color(red: 0.84, green: 0.34, blue: 0.24)
    }

    var body: some View {
        VStack(alignment: .center, spacing: AppTheme.Spacing.s3) {
            coverImage

            Text(album.name)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .lineLimit(2)
            
            HStack(alignment: .center, spacing: AppTheme.Spacing.s3) {
                HStack(spacing: AppTheme.Spacing.s1){
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.Colors.textSecondary.opacity(0.6))
                    
                    Text(momentCountText)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.Colors.textSecondary.opacity(0.6))
                        .fixedSize(horizontal: true, vertical: false)
                }

                if latestMomentCreatedText != nil {
                    Circle().fill(AppTheme.Colors.border).frame(width: 4, height: 4)
                }

                if let latestMomentCreatedText {
                    HStack(spacing: AppTheme.Spacing.s1) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.Colors.textSecondary.opacity(0.6))

                        Text(latestMomentCreatedText)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.Colors.textSecondary.opacity(0.6))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
            }
            
            AlbumTimelineSummaryView(
                momentNodeCount: displayedMomentNodeCount,
                showsReminderNode: showsReminderNode
            )
        }
        .padding(AppTheme.Spacing.s6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous)
                .fill(AppTheme.Colors.surface)
                .shadow(color: AppTheme.Colors.shadow, radius: AppTheme.Shadow.softRadius, y: AppTheme.Shadow.softYOffset)
        }
        .overlay(alignment: .topTrailing) {
            if let reminderCountdownText {
                Text(reminderCountdownText)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.Colors.accentStroke)
                    .padding(.horizontal, AppTheme.Spacing.s2)
                    .padding(.vertical, 2)
                    .background(
                        Capsule(style: .continuous)
                            .fill(AppTheme.Colors.accentSoft)
                    )
                    .padding(AppTheme.Spacing.s5)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var coverImage: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(backdropTransforms.enumerated().reversed()), id: \.offset) { index, transform in
                Rectangle()
                    .fill(AppTheme.Colors.border.opacity(0.5))
                    .border(AppTheme.Colors.border, width: 1)
                    .frame(width: imageSide, height: imageSide)
                    .rotationEffect(.degrees(transform.angle))
                    .offset(x: backdropLeadingInset + transform.x, y: transform.y)
            }

            LocalPhotoView(path: coverPhotoPath)
                .frame(width: imageSide, height: imageSide)
                .offset(x: backdropLeadingInset)
        }
        .frame(
            width: imageSide + backdropLeadingInset + backdropTrailingInset,
            height: imageSide + backdropBottomInset,
            alignment: .topLeading
        )
    }
}

private struct AlbumTimelineSummaryView: View {
    let momentNodeCount: Int
    let showsReminderNode: Bool

    private let maxNodeSlotCount = 6

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
            let leadingEmptySlotCount = max(maxNodeSlotCount - displayedNodeStyles.count, 0)
            let stepCount = max(maxNodeSlotCount - 1, 1)
            let usableWidth = max(0, lineEndX - lineStartX)

            ZStack {
                Path { path in
                    path.move(to: CGPoint(x: lineStartX, y: lineY))
                    path.addLine(to: CGPoint(x: lineEndX, y: lineY))
                }
                .stroke(
                    AppTheme.Colors.border,
                    style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [4, 4])
                )

                ForEach(Array(displayedNodeStyles.enumerated()), id: \.offset) { index, style in
                    let slotIndex = leadingEmptySlotCount + index
                    let progress = CGFloat(slotIndex) / CGFloat(stepCount)
                    AlbumTimelineNodeView(style: style)
                        .position(
                            x: lineStartX + usableWidth * progress,
                            y: lineY
                        )
                }
            }
        }
        .frame(height: 28)
    }
}

private struct AlbumTimelineNodeView: View {
    let style: AlbumTimelineNodeStyle

    var body: some View {
        Circle()
            .fill(fillColor)
            .frame(width: 10, height: 10)
            .overlay {
                Circle()
                    .stroke(strokeColor, style: strokeStyle)
            }
    }

    private var fillColor: Color {
        switch style {
        case .moment:
            return AppTheme.Colors.accent.opacity(0.5)
        case .reminder:
            return AppTheme.Colors.surface
        }
    }

    private var strokeColor: Color {
        switch style {
        case .moment:
            return AppTheme.Colors.accent.opacity(0.5)
        case .reminder:
            return AppTheme.Colors.accent.opacity(0.75)
        }
    }

    private var strokeStyle: StrokeStyle {
        switch style {
        case .moment:
            return StrokeStyle(lineWidth: 1)
        case .reminder:
            return StrokeStyle(lineWidth: 1, dash: [2, 2])
        }
    }
}

private enum AlbumTimelineNodeStyle {
    case moment
    case reminder
}

private struct CardLayerTransform {
    let x: CGFloat
    let y: CGFloat
    let angle: Double
}

#Preview {
    let album: Album = {
        let album = Album(name: "Weekend Escape")
        let _ = Moment(album: album, photo: "", location: "Kyoto", createdAt: .now.addingTimeInterval(-86_400 * 12))
        let _ = Moment(album: album, photo: "", location: "Osaka", createdAt: .now.addingTimeInterval(-86_400 * 2))
        album.remindValue = 1
        album.remindUnit = .week
        album.remindAt = .now.addingTimeInterval(86_400 * 4)
        return album
    }()

    AlbumCardView(
        album: album,
        coverPhotoPath: nil,
        momentCountText: "2 Moments",
        layerCount: 2,
        latestMomentCreatedText: "Apr 25, 2026",
        reminderCountdownText: "4 days later",
        displayedMomentNodeCount: 2,
        showsReminderNode: true
    )
        .padding()
        .background(AppTheme.Colors.background)
}
