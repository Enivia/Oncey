import CoreGraphics

enum MomentTimelineSceneResolver {
    static let maximumVisibleNeighbors = 4

    struct DetailStyle {
        let scale: CGFloat
        let opacity: CGFloat
        let verticalOffset: CGFloat
    }

    struct DragState {
        let focusPosition: CGFloat
        let targetIndex: Int
    }

    static func visibleIndices(
        momentCount: Int,
        focusPosition: CGFloat,
        maxVisibleSteps: Int
    ) -> [Int] {
        guard momentCount > 0, maxVisibleSteps >= 0 else {
            return []
        }

        let anchorIndex = clamp(Int(focusPosition.rounded()), lower: 0, upper: momentCount - 1)
        let visibleNeighborCount = min(maxVisibleSteps, maximumVisibleNeighbors)
        let lowerBound = max(0, anchorIndex - visibleNeighborCount)
        let upperBound = min(momentCount - 1, anchorIndex + visibleNeighborCount)

        return Array(lowerBound...upperBound)
    }

    static func detailStyle(for index: Int, focusPosition: CGFloat) -> DetailStyle {
        let relativeOffset = CGFloat(index) - focusPosition
        let visibility = normalizedFalloff(for: abs(relativeOffset), fullVisibilityDistance: 1)

        return DetailStyle(
            scale: 0.5 + (0.5 * visibility),
            opacity: visibility,
            verticalOffset: relativeOffset
        )
    }

    static func dragState(
        translation: CGFloat,
        predictedEndTranslation: CGFloat,
        stepDistance: CGFloat,
        momentCount: Int,
        currentSettledIndex: Int
    ) -> DragState {
        guard momentCount > 0 else {
            return DragState(focusPosition: 0, targetIndex: 0)
        }

        let maximumIndex = CGFloat(momentCount - 1)
        let settledIndex = clamp(CGFloat(currentSettledIndex), lower: 0, upper: maximumIndex)

        guard stepDistance > 0 else {
            let targetIndex = Int(settledIndex.rounded())
            return DragState(focusPosition: settledIndex, targetIndex: targetIndex)
        }

        let dragFocus = clamp(settledIndex - (translation / stepDistance), lower: 0, upper: maximumIndex)
        let predictedFocus = settledIndex - (predictedEndTranslation / stepDistance)
        let targetIndex = clamp(Int(predictedFocus.rounded()), lower: 0, upper: momentCount - 1)

        return DragState(focusPosition: dragFocus, targetIndex: targetIndex)
    }

    private static func normalizedFalloff(for distance: CGFloat, fullVisibilityDistance: CGFloat) -> CGFloat {
        guard fullVisibilityDistance > 0 else {
            return 0
        }

        return clamp(1 - (distance / fullVisibilityDistance), lower: 0, upper: 1)
    }

    private static func clamp(_ value: CGFloat, lower: CGFloat, upper: CGFloat) -> CGFloat {
        min(max(value, lower), upper)
    }

    private static func clamp(_ value: Int, lower: Int, upper: Int) -> Int {
        min(max(value, lower), upper)
    }
}
