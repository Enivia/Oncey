import CoreGraphics
import Testing
@testable import Oncey

struct MomentTimelinePageMetricsTests {

    @Test func pageHeightUsesSeventyPercentOfContainerHeight() {
        let metrics = MomentTimelinePageMetrics(containerSize: CGSize(width: 360, height: 1_000))

        #expect(isClose(metrics.pageSize.width, 360))
        #expect(isClose(metrics.pageSize.height, 700))
        #expect(isClose(metrics.verticalInset, 150))
    }

    @Test func photoBoundsReserveTimestampNoteAndSpacingHeights() {
        let metrics = MomentTimelinePageMetrics(containerSize: CGSize(width: 360, height: 1_000))
        let expectedPhotoHeight = metrics.pageSize.height - metrics.timestampHeight - metrics.noteHeight - metrics.contentSpacing * 2

        #expect(isClose(metrics.photoMaxSize.width, 360 - metrics.horizontalPadding * 2))
        #expect(isClose(metrics.photoMaxSize.height, expectedPhotoHeight))
        #expect(metrics.noteHeight > 0)
    }

    @Test func fittedPhotoSizePreservesAspectRatioWithinBounds() {
        let metrics = MomentTimelinePageMetrics(containerSize: CGSize(width: 360, height: 1_000))

        let fittedSize = metrics.fittedPhotoSize(for: CGSize(width: 1_200, height: 1_800))
        let expectedAspectRatio = CGFloat(1_200) / CGFloat(1_800)

        #expect(isClose(fittedSize.width, metrics.photoMaxSize.width))
        #expect(fittedSize.height <= metrics.photoMaxSize.height)
        #expect(isClose(fittedSize.width / fittedSize.height, expectedAspectRatio, tolerance: 0.0001))
    }

    @Test func contentColumnWidthMatchesFittedPhotoWidth() {
        let metrics = MomentTimelinePageMetrics(containerSize: CGSize(width: 360, height: 1_000))
        let sourceSize = CGSize(width: 1_600, height: 900)

        #expect(isClose(metrics.contentColumnWidth(for: sourceSize), metrics.fittedPhotoSize(for: sourceSize).width))
    }

    private func isClose(_ lhs: CGFloat, _ rhs: CGFloat, tolerance: CGFloat = 0.001) -> Bool {
        abs(lhs - rhs) <= tolerance
    }
}