import CoreGraphics
import Testing
@testable import Oncey

struct CameraPreviewRotationResolverTests {
    @Test func previewAngleRemainsPortraitAnchoredForLandscapeCaptureAngle() {
        let resolvedAngle = CameraPreviewRotationResolver.resolve(captureRotationAngle: 0)

        #expect(resolvedAngle == 90)
    }

    @Test func previewAngleRemainsPortraitAnchoredForPortraitCaptureAngle() {
        let resolvedAngle = CameraPreviewRotationResolver.resolve(captureRotationAngle: 90)

        #expect(resolvedAngle == 90)
    }
}