import SwiftUI

struct MomentComparisonSlider: View {
    private enum InteractionZone {
        case leading
        case trailing
        case divider
    }

    let leadingMoment: Moment
    let trailingMoment: Moment
    let aspectRatio: CGFloat
    let activeSide: MomentComparisonState.Side?
    let onTapSide: (MomentComparisonState.Side) -> Void

    private let handleHitWidth: CGFloat = 56
    private let handleDiameter: CGFloat = 44
    private let tapTranslationTolerance: CGFloat = 10

    @State private var splitRatio: CGFloat = 0.5
    @State private var committedSplitRatio: CGFloat = 0.5
    @State private var interactionZone: InteractionZone?

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let dividerX = resolvedLeadingWidth(for: size.width)

            ZStack(alignment: .leading) {
                comparisonPhoto(path: trailingMoment.photo)
                    .frame(width: size.width, height: size.height)

                comparisonPhoto(path: leadingMoment.photo)
                    .frame(width: size.width, height: size.height)
                    .frame(width: dividerX, alignment: .leading)
                    .clipped()

                if let activeSide {
                    activeSelectionOverlay(
                        side: activeSide,
                        leadingWidth: dividerX,
                        totalWidth: size.width,
                        height: size.height
                    )
                }

                handle(
                    height: size.height,
                    dividerX: dividerX
                )

                interactionLayer(containerWidth: size.width, height: size.height, dividerX: dividerX)
            }
            .background(AppTheme.Colors.surface)
            .overlay {
                Rectangle()
                    .stroke(AppTheme.Colors.border, lineWidth: 1)
            }
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
    }

    private func comparisonPhoto(path: String?) -> some View {
        LocalPhotoView(path: path, contentMode: .fit)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func activeSelectionOverlay(
        side: MomentComparisonState.Side,
        leadingWidth: CGFloat,
        totalWidth: CGFloat,
        height: CGFloat
    ) -> some View {
        let isLeading = side == .leading
        let overlayWidth = isLeading ? leadingWidth : max(0, totalWidth - leadingWidth)
        let overlayColor = isLeading ? AppTheme.Colors.accent : AppTheme.Colors.secondary

        return Rectangle()
            .stroke(overlayColor, lineWidth: 3)
            .frame(width: overlayWidth, height: height)
            .offset(x: isLeading ? 0 : leadingWidth)
            .allowsHitTesting(false)
    }

    private func handle(height: CGFloat, dividerX: CGFloat) -> some View {
        ZStack {
            Rectangle()
                .fill(Color.white.opacity(0.96))
                .frame(width: 2, height: height)

            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: handleDiameter, height: handleDiameter)
                .overlay {
                    Image(systemName: "arrow.left.and.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                }
                .shadow(color: AppTheme.Colors.shadowEmphasis, radius: AppTheme.Shadow.emphasizedRadius, y: AppTheme.Shadow.emphasizedYOffset)
        }
        .frame(width: handleHitWidth, height: height)
        .position(x: dividerX, y: height / 2)
        .allowsHitTesting(false)
        .zIndex(1)
    }

    private func interactionLayer(containerWidth: CGFloat, height: CGFloat, dividerX: CGFloat) -> some View {
        Rectangle()
            .fill(Color.white.opacity(0.001))
            .frame(width: containerWidth, height: height)
            .contentShape(Rectangle())
            .highPriorityGesture(interactionGesture(containerWidth: containerWidth, dividerX: dividerX))
            .zIndex(2)
    }

    private func interactionGesture(containerWidth: CGFloat, dividerX: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if interactionZone == nil {
                    interactionZone = interactionZone(for: value.startLocation.x, dividerX: dividerX)
                }

                guard interactionZone == .divider else {
                    return
                }

                let committedX = containerWidth * committedSplitRatio
                splitRatio = clampedSplitRatio(
                    for: committedX + value.translation.width,
                    containerWidth: containerWidth
                )
            }
            .onEnded { value in
                defer {
                    interactionZone = nil
                }

                switch interactionZone {
                case .divider:
                    committedSplitRatio = splitRatio
                case .leading:
                    if isTap(value.translation) {
                        onTapSide(.leading)
                    }
                case .trailing:
                    if isTap(value.translation) {
                        onTapSide(.trailing)
                    }
                case nil:
                    break
                }
            }
    }

    private func interactionZone(for startX: CGFloat, dividerX: CGFloat) -> InteractionZone {
        if abs(startX - dividerX) <= handleHitWidth / 2 {
            return .divider
        }

        return startX < dividerX ? .leading : .trailing
    }

    private func isTap(_ translation: CGSize) -> Bool {
        abs(translation.width) <= tapTranslationTolerance && abs(translation.height) <= tapTranslationTolerance
    }

    private func resolvedLeadingWidth(for containerWidth: CGFloat) -> CGFloat {
        clampedSplitRatio(for: containerWidth * splitRatio, containerWidth: containerWidth) * containerWidth
    }

    private func clampedSplitRatio(for proposedX: CGFloat, containerWidth: CGFloat) -> CGFloat {
        guard containerWidth > 0 else {
            return 0.5
        }

        let minimumVisibleWidth = min(100, containerWidth / 2)
        let clampedX = min(max(proposedX, minimumVisibleWidth), max(minimumVisibleWidth, containerWidth - minimumVisibleWidth))
        return clampedX / containerWidth
    }
}