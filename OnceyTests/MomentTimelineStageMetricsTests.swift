import CoreGraphics
import Testing
@testable import Oncey

struct MomentTimelineStageMetricsTests {

    private let portraitPhotoSize = CGSize(width: 1200, height: 1600)

    @Test func resolveFallsBackToAlbumAspectRatioWhenPhotoSizeIsUnavailable() {
        let containerSize = CGSize(width: 430, height: 932)
        let expectedPhotoWidth = containerSize.width * 0.7
        let metrics = MomentTimelineStageMetrics.resolve(
            containerSize: containerSize,
            albumAspectRatio: CameraCaptureAspect.square.aspectRatio
        )

        #expect(abs(metrics.maxPhotoSize.width - expectedPhotoWidth) < 0.0001)
        #expect(abs(metrics.maxPhotoSize.height - expectedPhotoWidth) < 0.0001)
    }
}
