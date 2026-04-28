import SwiftUI

struct MomentTimelineStageMetrics {
    let stageSize: CGSize
    let stepDistance: CGFloat
    let neighborRowHeight: CGFloat
    let horizontalInset: CGFloat
    let leading: CGFloat
    let contentLeading: CGFloat
    let contentSpacing: CGFloat
    let maxPhotoSize: CGSize
    let focusedNodeY: CGFloat
    let focusedDetailTopY: CGFloat
    let focusedDetailBottomY: CGFloat
    let firstLowerNodeY: CGFloat
    let detailTravelDistance: CGFloat

    static func resolve(
        containerSize: CGSize,
        albumAspectRatio: CGFloat
    ) -> MomentTimelineStageMetrics {
        let neighborCount = CGFloat(MomentTimelineSceneResolver.maximumVisibleNeighbors)
        let neighborRowHeight: CGFloat = 40

        let leading: CGFloat = 56
        let contentLeading = AppTheme.Spacing.s5
        let contentSpacing = AppTheme.Spacing.s2
        let focusedRowHeight: CGFloat = 40
        let noteHeight: CGFloat = 50
        
        let horizontalInset = AppTheme.Spacing.s8
        let verticalInset = AppTheme.Spacing.s2
        
        let stageWidth = containerSize.width - horizontalInset * 2
        let stageHeight = containerSize.height - verticalInset * 2
        
        let neighborHeight = neighborRowHeight * neighborCount * 2
        let extraContentHeight = noteHeight + contentSpacing + focusedRowHeight
        let photoBounds = CGSize(
            width: stageWidth - leading - contentLeading,
            height: stageHeight - neighborHeight - extraContentHeight
        )
        let referencePhotoSize = CGSize(width: albumAspectRatio, height: 1)
        let maxPhotoSize = AppTheme.Layout.fittedSize(for: referencePhotoSize, maxSize: photoBounds)

        let focusedMomentTopY = (stageHeight - (maxPhotoSize.height + extraContentHeight)) / 2
        let focusedNodeY = focusedMomentTopY + (focusedRowHeight / 2)
        let focusedDetailTopY = focusedMomentTopY + focusedRowHeight
        let focusedDetailBottomY = focusedDetailTopY + maxPhotoSize.height + noteHeight
        let firstLowerNodeY = focusedDetailBottomY + AppTheme.Spacing.s5
        let detailTravelDistance = maxPhotoSize.height + noteHeight

        return MomentTimelineStageMetrics(
            stageSize: CGSize(width: stageWidth, height: stageHeight),
            stepDistance: max(detailTravelDistance, 1),
            neighborRowHeight: neighborRowHeight,
            horizontalInset: horizontalInset,
            leading: leading,
            contentLeading: contentLeading,
            contentSpacing: contentSpacing,
            maxPhotoSize: maxPhotoSize,
            focusedNodeY: focusedNodeY,
            focusedDetailTopY: focusedDetailTopY,
            focusedDetailBottomY: focusedDetailBottomY,
            firstLowerNodeY: firstLowerNodeY,
            detailTravelDistance: detailTravelDistance
        )
    }

    func nodeY(forSlotOffset slotOffset: Int) -> CGFloat {
        if slotOffset < 0 {
            return focusedNodeY + (CGFloat(slotOffset) * neighborRowHeight)
        }

        if slotOffset == 0 {
            return focusedNodeY
        }

        return firstLowerNodeY + (CGFloat(slotOffset - 1) * neighborRowHeight)
    }

    func nodeY(for index: Int, focusPosition: CGFloat) -> CGFloat {
        let lowerAnchor = Int(floor(focusPosition))
        let upperAnchor = Int(ceil(focusPosition))
        let progress = focusPosition - CGFloat(lowerAnchor)
        let lowerY = nodeY(forSlotOffset: index - lowerAnchor)
        let upperY = nodeY(forSlotOffset: index - upperAnchor)

        return lowerY + ((upperY - lowerY) * progress)
    }

    func detailTopY(for relativeOffset: CGFloat) -> CGFloat {
        focusedDetailTopY + (relativeOffset * detailTravelDistance)
    }
}

struct MomentTimelineStageView: View {
    let moments: [Moment]
    let focusPosition: CGFloat
    let metrics: MomentTimelineStageMetrics
    let albumAspectRatio: CGFloat?
    let timestampTextProvider: (Moment) -> String
    let onShare: (Moment) -> Void
    let onDelete: (Moment) -> Void

    private let maxVisibleSteps = 6

    private var visibleIndices: [Int] {
        MomentTimelineSceneResolver.visibleIndices(
            momentCount: moments.count,
            focusPosition: focusPosition,
            maxVisibleSteps: maxVisibleSteps
        )
    }

    private var activeIndex: Int {
        guard !moments.isEmpty else {
            return 0
        }

        return min(max(Int(focusPosition.rounded()), 0), moments.count - 1)
    }

    private var detailIndices: [Int] {
        visibleIndices
            .filter { index in
                MomentTimelineSceneResolver.detailStyle(for: index, focusPosition: focusPosition).opacity > 0.001
            }
            .sorted { lhs, rhs in
                abs(CGFloat(lhs) - focusPosition) > abs(CGFloat(rhs) - focusPosition)
            }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            rail

            ForEach(visibleIndices, id: \.self) { index in
                timestampEntry(for: index)
            }

            ForEach(detailIndices, id: \.self) { index in
                detailCard(for: index)
            }
        }
        .frame(width: metrics.stageSize.width, height: metrics.stageSize.height)
        .contentShape(Rectangle())
    }

    private var rail: some View {
        ZStack(alignment: .topLeading) {
            if let firstIndex = visibleIndices.first, let lastIndex = visibleIndices.last, firstIndex != lastIndex {
                let firstNodeY = metrics.nodeY(for: firstIndex, focusPosition: focusPosition)
                let lastNodeY = metrics.nodeY(for: lastIndex, focusPosition: focusPosition)

                Path { path in
                    path.move(to: CGPoint(x: 0, y: firstNodeY))
                    path.addLine(to: CGPoint(x: 0, y: lastNodeY))
                }
                .stroke(
                    AppTheme.Colors.divider,
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [4, 6])
                )
            }
        }
    }

    private func timestampEntry(for index: Int) -> some View {
        let isFocused = index == activeIndex
        let nodeY = metrics.nodeY(for: index, focusPosition: focusPosition)
        let nodeSize = isFocused ? 16.0 : 12.0

        return ZStack(alignment: .topLeading) {
            Circle()
                .fill(isFocused ? AppTheme.Colors.accent : AppTheme.Colors.accentSoft)
                .frame(width: nodeSize, height: nodeSize)
                .overlay {
                    Circle()
                        .stroke(AppTheme.Colors.surface, lineWidth: 2)
                }
                .position(y: nodeY)

            Text(timestampTextProvider(moments[index]))
                .font(isFocused ? .body.weight(.semibold) : .subheadline)
                .foregroundStyle(AppTheme.Colors.textPrimary.opacity(1 - 0.2 * abs(CGFloat(index) - focusPosition)))
                .position(
                    x: metrics.leading + metrics.horizontalInset + metrics.contentLeading + (isFocused ? metrics.contentLeading : 0),
                    y: nodeY
                )
        }
    }

    private func detailCard(for index: Int) -> some View {
        let style = MomentTimelineSceneResolver.detailStyle(for: index, focusPosition: focusPosition)
        let moment = moments[index]
        let photoSize = photoDisplaySize(for: moment)

        return NavigationLink {
            MomentEditorView(mode: .editMoment(moment: moment))
        } label: {
            VStack(alignment: .leading, spacing: metrics.contentSpacing) {
                photoView(for: moment, photoSize: photoSize)

                if !moment.note.isEmpty {
                    Text(moment.note)
                        .font(.subheadline.italic())
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .lineLimit(2)
                }
            }
            .padding(.leading, metrics.contentLeading)
            .frame(alignment: .leading)
            .scaleEffect(style.scale, anchor: style.verticalOffset >= 0 ? .topLeading : .bottomLeading)
            .opacity(style.opacity)
            .offset(y: metrics.detailTopY(for: style.verticalOffset))
        }
        .buttonStyle(.plain)
        .allowsHitTesting(style.opacity > 0.6)
    }

    private func photoView(for moment: Moment, photoSize: CGSize) -> some View {
        let previewShape = RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous)

        return LocalPhotoView(path: moment.photo, contentMode: .fit)
            .frame(width: photoSize.width, height: photoSize.height)
            .clipShape(previewShape)
            .contentShape(.interaction, previewShape)
            .contentShape(.contextMenuPreview, previewShape)
            .shadow(color: AppTheme.Colors.shadow, radius: AppTheme.Shadow.softRadius, y: AppTheme.Shadow.softYOffset)
            .contextMenu {
                Button {
                    onShare(moment)
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }

                Button(role: .destructive) {
                    onDelete(moment)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } preview: {
                LocalPhotoView(path: moment.photo, contentMode: .fit)
                    .frame(width: photoSize.width, height: photoSize.height)
                    .clipShape(previewShape)
            }
    }
    
    private func photoDisplaySize(for moment: Moment) -> CGSize {
        guard let imageSize = ImageResourceService.imageSize(from: moment.photo) else {
            guard let albumAspectRatio, albumAspectRatio > 0 else {
                return metrics.maxPhotoSize
            }

            return AppTheme.Layout.fittedSize(
                for: CGSize(width: albumAspectRatio, height: 1),
                maxSize: metrics.maxPhotoSize
            )
        }

        return AppTheme.Layout.fittedSize(for: imageSize, maxSize: metrics.maxPhotoSize)
    }
}
