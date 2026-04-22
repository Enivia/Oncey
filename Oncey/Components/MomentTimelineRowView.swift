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
        HStack(alignment: .top, spacing: 18) {
            TimelineRailView(isFirst: isFirst, isLast: isLast)

            VStack(alignment: .leading, spacing: 12) {
                Text(timestampText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                photoContent

                if bottomSpacing > 0 {
                    Color.clear
                        .frame(height: bottomSpacing)
                }
            }
        }
    }

    private var photoContent: some View {
        let imageCard = ZStack(alignment: .topTrailing) {
            LocalPhotoView(path: moment.photo)
                .aspectRatio(4 / 3, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(selectionStrokeColor, lineWidth: isSelected ? 2 : 1)
                }
                .shadow(color: .black.opacity(0.06), radius: 20, y: 8)

            if isSelectionMode {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.accentColor : .white)
                    .padding(14)
                    .shadow(color: .black.opacity(0.16), radius: 8, y: 4)
            }
        }

        return imageCard.contextMenu {
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

    private var selectionStrokeColor: Color {
        if isSelected {
            return .accentColor
        }

        return Color.primary.opacity(0.06)
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
                .stroke(Color.secondary.opacity(0.28), style: StrokeStyle(lineWidth: 2, lineCap: .round))

                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 12, height: 12)
                    .overlay {
                        Circle()
                            .stroke(.background, lineWidth: 4)
                    }
                    .position(x: centerX, y: nodeCenterY)
            }
        }
        .frame(width: 28)
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