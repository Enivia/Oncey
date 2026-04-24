//
//  MomentTimelineRowView.swift
//  Oncey
//

import SwiftUI

struct MomentTimelineRowView: View {
    let moment: Moment
    let timestampText: String
    let isFirst: Bool
    let isLast: Bool
    let bottomSpacing: CGFloat
    let isSelectionMode: Bool
    let isSelected: Bool
    let onMultiSelect: (() -> Void)?
    let onShare: (() -> Void)?
    let onDelete: (() -> Void)?

    init(
        moment: Moment,
        timestampText: String,
        isFirst: Bool,
        isLast: Bool,
        bottomSpacing: CGFloat,
        isSelectionMode: Bool,
        isSelected: Bool,
        onMultiSelect: (() -> Void)? = nil,
        onShare: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil
    ) {
        self.moment = moment
        self.timestampText = timestampText
        self.isFirst = isFirst
        self.isLast = isLast
        self.bottomSpacing = bottomSpacing
        self.isSelectionMode = isSelectionMode
        self.isSelected = isSelected
        self.onMultiSelect = onMultiSelect
        self.onShare = onShare
        self.onDelete = onDelete
    }

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.s3) {
            TimelineRailView(isFirst: isFirst, isLast: isLast)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.s3) {
                Text(timestampText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .padding(.top, 12)

                photoContent
            }.padding(.bottom, bottomSpacing)
        }
    }

    private var photoContent: some View {
        let imageCard = LocalPhotoView(path: moment.photo, contentMode: .fit)
            .frame(width: photoDisplaySize.width, height: photoDisplaySize.height)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous)
                    .stroke(selectionStrokeColor, lineWidth: 2)
            }
            .overlay(alignment: .topTrailing) {
                if isSelectionMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.surface)
                        .padding(AppTheme.Spacing.s4)
                        .shadow(color: AppTheme.Colors.shadowEmphasis, radius: AppTheme.Shadow.emphasizedRadius, y: AppTheme.Shadow.emphasizedYOffset)
                }
            }
            .shadow(color: AppTheme.Colors.shadow, radius: AppTheme.Shadow.softRadius, y: AppTheme.Shadow.softYOffset)

        return imageCard
            .contextMenu {
            if !isSelectionMode {
                if let onMultiSelect {
                    Button(action: onMultiSelect) {
                        Label("Multi-select", systemImage: "checklist")
                    }
                }

                if let onShare {
                    Button(action: onShare) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }

                if let onDelete {
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }

    private var photoDisplaySize: CGSize {
        let fallbackSize = CGSize(width: maxPhotoDimension, height: maxPhotoDimension * 0.75)

        guard let imageSize = ImageResourceService.imageSize(from: moment.photo) else {
            return fallbackSize
        }

        return AppTheme.Layout.fittedSize(for: imageSize, maxDimension: maxPhotoDimension)
    }

    private var maxPhotoDimension: CGFloat {
        AppTheme.Layout.screenWidth * AppTheme.Layout.timelinePhotoMaxWidthRatio
    }

    private var selectionStrokeColor: Color {
        if isSelected {
            return AppTheme.Colors.accentStroke
        }

        return Color.clear
    }
}

private struct TimelineRailView: View {
    let isFirst: Bool
    let isLast: Bool

    var body: some View {
        GeometryReader { geometry in
            let centerX = geometry.size.width / 2
            let nodeCenterY: CGFloat = 22

            ZStack(alignment: .top) {
                Path { path in
                    if !isFirst {
                        path.move(to: CGPoint(x: centerX, y: 0))
                        path.addLine(to: CGPoint(x: centerX, y: nodeCenterY))
                    }

                    if !isLast {
                        path.move(to: CGPoint(x: centerX, y: nodeCenterY))
                        path.addLine(to: CGPoint(x: centerX, y: geometry.size.height))
                    }
                }
                .stroke(AppTheme.Colors.divider, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))

                Circle()
                    .fill(AppTheme.Colors.accent)
                    .frame(width: 12, height: 12)
                    .overlay {
                        Circle()
                            .stroke(AppTheme.Colors.surface, lineWidth: 2)
                    }
                    .position(x: centerX, y: nodeCenterY)
            }
        }
        .frame(width: 24)
    }
}

#Preview {
    let album = Album(name: "Timeline Preview")
    let moment = Moment(album: album, photo: "", location: "Berlin, Germany")

    MomentTimelineRowView(
        moment: moment,
        timestampText: "Apr 18, 2026 at 7:05 PM",
        isFirst: true,
        isLast: false,
        bottomSpacing: 30,
        isSelectionMode: true,
        isSelected: true
    )
        .padding()
}
