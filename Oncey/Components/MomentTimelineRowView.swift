//
//  MomentTimelineRowView.swift
//  Oncey
//

import SwiftUI

struct MomentTimelineRowView: View {
    let moment: Moment
    let timestampText: String
    let metrics: MomentTimelinePageMetrics
    let isCurrent: Bool
    let onEditNote: (() -> Void)?
    let onShare: (() -> Void)?
    let onDelete: (() -> Void)?

    init(
        moment: Moment,
        timestampText: String,
        metrics: MomentTimelinePageMetrics,
        isCurrent: Bool,
        onEditNote: (() -> Void)? = nil,
        onShare: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil
    ) {
        self.moment = moment
        self.timestampText = timestampText
        self.metrics = metrics
        self.isCurrent = isCurrent
        self.onEditNote = onEditNote
        self.onShare = onShare
        self.onDelete = onDelete
    }

    var body: some View {
        pageContent
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, metrics.horizontalPadding)
            .contentShape(Rectangle())
            .opacity(isCurrent ? 1 : 0.3)
            .animation(.easeOut(duration: 0.3), value: isCurrent)
            .contextMenu {
                if let onEditNote {
                    Button(action: onEditNote) {
                        Label("Note", systemImage: "long.text.page.and.pencil")
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

    private var pageContent: some View {
        VStack(spacing: metrics.contentSpacing) {
            timestampRow
            contentColumn
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var contentColumn: some View {
        VStack(alignment: .leading, spacing: metrics.contentSpacing) {
            photoContent
            noteRow
        }
        .frame(width: contentColumnWidth, alignment: .leading)
    }

    private var timestampRow: some View {
        HStack(spacing: AppTheme.Spacing.s3) {
            Circle()
                .fill(isCurrent ? AppTheme.Colors.accent : AppTheme.Colors.accentSoft)
                .stroke(AppTheme.Colors.surface, lineWidth: 2)
                .frame(width: AppTheme.Layout.timelineDotSize, height: AppTheme.Layout.timelineDotSize)

            Text(timestampText)
                .font(.subheadline.weight(isCurrent ? .semibold : .medium))
                .foregroundStyle(AppTheme.Colors.textPrimary)
        }
        .frame(height: metrics.timestampHeight)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var photoContent: some View {
        LocalPhotoView(path: moment.photo, contentMode: .fit)
            .frame(width: photoDisplaySize.width, height: photoDisplaySize.height)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl, style: .continuous))
            .shadow(color: AppTheme.Colors.shadow, radius: AppTheme.Shadow.softRadius, y: AppTheme.Shadow.softYOffset)
    }

    private var noteRow: some View {
        Text(moment.note.isEmpty ? " " : moment.note)
            .font(.subheadline)
            .foregroundStyle(AppTheme.Colors.textPrimary)
            .lineLimit(1)
            .truncationMode(.tail)
            .multilineTextAlignment(.center)
            .frame(width: contentColumnWidth, height: metrics.noteHeight, alignment: .center)
            .accessibilityLabel(moment.note.isEmpty ? "No note" : moment.note)
    }

    private var contentColumnWidth: CGFloat {
        metrics.contentColumnWidth(for: resolvedPhotoSourceSize)
    }

    private var photoDisplaySize: CGSize {
        metrics.fittedPhotoSize(for: resolvedPhotoSourceSize)
    }

    private var resolvedPhotoSourceSize: CGSize {
        ImageResourceService.imageSize(from: moment.photo) ?? CGSize(width: 4, height: 3)
    }
}

#Preview {
    let album = Album(name: "Timeline Preview")
    let moment = Moment(album: album, photo: "", note: "Today is such a good day!")

    MomentTimelineRowView(
        moment: moment,
        timestampText: "Apr 18, 2026 at 7:05 PM",
        metrics: MomentTimelinePageMetrics(containerSize: CGSize(width: 360, height: 780)),
        isCurrent: true
    )
    .frame(height: 546)
    .padding()
}
