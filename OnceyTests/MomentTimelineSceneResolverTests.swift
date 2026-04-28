import CoreGraphics
import Testing
@testable import Oncey

struct MomentTimelineSceneResolverTests {

    @Test func visibleIndicesAtTopShowNewestAndNextSixMoments() {
        let indices = MomentTimelineSceneResolver.visibleIndices(
            momentCount: 12,
            focusPosition: .zero,
            maxVisibleSteps: 6
        )

        #expect(indices == [0, 1, 2, 3, 4, 5, 6])
    }

    @Test func visibleIndicesInMiddleKeepAtMostSixNeighborsOnEachSide() {
        let indices = MomentTimelineSceneResolver.visibleIndices(
            momentCount: 20,
            focusPosition: 10,
            maxVisibleSteps: 6
        )

        #expect(indices == [4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16])
    }

    @Test func visibleIndicesNearBottomClipToAvailableRange() {
        let indices = MomentTimelineSceneResolver.visibleIndices(
            momentCount: 12,
            focusPosition: 11,
            maxVisibleSteps: 6
        )

        #expect(indices == [5, 6, 7, 8, 9, 10, 11])
    }

    @Test func visibleIndicesNeverExposeMoreThanSixNeighborsPerSide() {
        let indices = MomentTimelineSceneResolver.visibleIndices(
            momentCount: 24,
            focusPosition: 12,
            maxVisibleSteps: 20
        )

        #expect(indices == [6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18])
    }

    @Test func visibleIndicesStayStableUntilFocusCrossesTheNextHalfStep() {
        let slightForward = MomentTimelineSceneResolver.visibleIndices(
            momentCount: 20,
            focusPosition: 10.01,
            maxVisibleSteps: 6
        )
        let nearMidpoint = MomentTimelineSceneResolver.visibleIndices(
            momentCount: 20,
            focusPosition: 10.49,
            maxVisibleSteps: 6
        )
        let pastMidpoint = MomentTimelineSceneResolver.visibleIndices(
            momentCount: 20,
            focusPosition: 10.51,
            maxVisibleSteps: 6
        )

        #expect(slightForward == [4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16])
        #expect(nearMidpoint == [4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16])
        #expect(pastMidpoint == [5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17])
    }

    @Test func dragStateUsesPredictedEndTranslationForTargetAndClampsToBounds() {
        let upward = MomentTimelineSceneResolver.dragState(
            translation: -120,
            predictedEndTranslation: -320,
            stepDistance: 80,
            momentCount: 6,
            currentSettledIndex: 2
        )
        let downward = MomentTimelineSceneResolver.dragState(
            translation: 120,
            predictedEndTranslation: 480,
            stepDistance: 80,
            momentCount: 6,
            currentSettledIndex: 2
        )

        #expect(abs(upward.focusPosition - 3.5) < 0.0001)
        #expect(upward.targetIndex == 5)
        #expect(abs(downward.focusPosition - 0.5) < 0.0001)
        #expect(downward.targetIndex == 0)
    }

    @Test func dragStateWithNonPositiveStepDistanceKeepsTheClampedSettledIndex() {
        let zeroStep = MomentTimelineSceneResolver.dragState(
            translation: -120,
            predictedEndTranslation: -320,
            stepDistance: 0,
            momentCount: 6,
            currentSettledIndex: 8
        )
        let negativeStep = MomentTimelineSceneResolver.dragState(
            translation: 120,
            predictedEndTranslation: 320,
            stepDistance: -40,
            momentCount: 6,
            currentSettledIndex: -3
        )

        #expect(zeroStep.focusPosition == 5)
        #expect(zeroStep.targetIndex == 5)
        #expect(negativeStep.focusPosition == 0)
        #expect(negativeStep.targetIndex == 0)
    }

    @Test func nodeWeightAndDetailVisibilityDecayWithDistance() {
        let focusedNode = MomentTimelineSceneResolver.nodeWeight(for: 4, focusPosition: 4)
        let adjacentNode = MomentTimelineSceneResolver.nodeWeight(for: 5, focusPosition: 4)
        let distantNode = MomentTimelineSceneResolver.nodeWeight(for: 7, focusPosition: 4)

        #expect(focusedNode.relativeOffset == 0)
        #expect(focusedNode.nodeSize > adjacentNode.nodeSize)
        #expect(adjacentNode.nodeSize > distantNode.nodeSize)
        #expect(focusedNode.nodeOpacity > adjacentNode.nodeOpacity)
        #expect(adjacentNode.nodeOpacity > distantNode.nodeOpacity)
        #expect(focusedNode.timestampOpacity > adjacentNode.timestampOpacity)
        #expect(adjacentNode.timestampOpacity > distantNode.timestampOpacity)

        let currentDetail = MomentTimelineSceneResolver.detailStyle(for: 2, focusPosition: 2.25)
        let enteringDetail = MomentTimelineSceneResolver.detailStyle(for: 3, focusPosition: 2.25)
        let previousDetail = MomentTimelineSceneResolver.detailStyle(for: 1, focusPosition: 2.25)
        let farDetail = MomentTimelineSceneResolver.detailStyle(for: 5, focusPosition: 2.25)

        #expect(currentDetail.opacity > enteringDetail.opacity)
        #expect(enteringDetail.opacity > farDetail.opacity)
        #expect(currentDetail.scale > enteringDetail.scale)
        #expect(enteringDetail.scale > farDetail.scale)
        #expect(abs(currentDetail.verticalOffset) < abs(enteringDetail.verticalOffset))
        #expect(abs(enteringDetail.verticalOffset) < abs(farDetail.verticalOffset))
        #expect(previousDetail.verticalOffset < 0)
        #expect(enteringDetail.verticalOffset > 0)
        #expect(abs(enteringDetail.verticalOffset - 0.75) < 0.0001)
        #expect(farDetail.opacity == 0)
    }
}