import CoreGraphics
import Testing
#if canImport(UIKit)
import UIKit
#endif
@testable import Oncey

struct CameraGeometryTests {

    @Test func captureStageLayoutPinsThreeByFourReferenceToTopOfNineBySixteenStage() {
        let layout = CameraGeometry.captureStageLayout(
            stageWidth: 360,
            aspect: .threeByFour,
            bottomInset: 8
        )

        #expect(isClose(layout.stageRect.minX, 0))
        #expect(isClose(layout.stageRect.minY, 0))
        #expect(isClose(layout.stageRect.width, 360))
        #expect(isClose(layout.stageRect.height, 640))
        #expect(isClose(layout.referenceRect.minY, 0))
        #expect(isClose(layout.referenceRect.height, 480))
        #expect(layout.frameRect == layout.referenceRect)
        #expect(isClose(layout.maskSliderBottomY, 472))
        #expect(isClose(layout.captureControlsBottomY, 632))
    }

    @Test func captureStageLayoutCentersSquareInsideTopAlignedThreeByFourReference() {
        let layout = CameraGeometry.captureStageLayout(
            stageWidth: 360,
            aspect: .square,
            bottomInset: 8
        )

        #expect(isClose(layout.referenceRect.minY, 0))
        #expect(isClose(layout.referenceRect.height, 480))
        #expect(isClose(layout.frameRect.minY, 60))
        #expect(isClose(layout.frameRect.height, 360))
        #expect(isClose(layout.frameRect.width, 360))
        #expect(isClose(layout.maskSliderBottomY, 472))
        #expect(isClose(layout.captureControlsBottomY, 632))
    }

    @Test func captureStageLayoutUsesFullNineBySixteenStageWhenRequested() {
        let layout = CameraGeometry.captureStageLayout(
            stageWidth: 360,
            aspect: .nineBySixteen,
            bottomInset: 8
        )

        #expect(layout.frameRect == layout.stageRect)
        #expect(isClose(layout.referenceRect.minY, 0))
        #expect(isClose(layout.referenceRect.height, 480))
        #expect(isClose(layout.maskSliderBottomY, 472))
        #expect(isClose(layout.captureControlsBottomY, 632))
    }

    @Test func aspectCycleUsesRequestedOrder() {
        #expect(CameraCaptureAspect.threeByFour.next == .square)
        #expect(CameraCaptureAspect.square.next == .nineBySixteen)
        #expect(CameraCaptureAspect.nineBySixteen.next == .threeByFour)
    }

    @Test func squareCropUsesCenteredVerticalSlice() {
        let cropRect = CameraGeometry.cropRect(
            for: CGSize(width: 400, height: 800),
            aspect: .square
        )

        #expect(cropRect.origin.x == 0)
        #expect(cropRect.origin.y == 200)
        #expect(cropRect.width == 400)
        #expect(cropRect.height == 400)
    }

    @Test func threeByFourCropUsesCenteredHorizontalSlice() {
        let cropRect = CameraGeometry.cropRect(
            for: CGSize(width: 1600, height: 1200),
            aspect: .threeByFour
        )

        #expect(isClose(cropRect.origin.x, 350))
        #expect(cropRect.origin.y == 0)
        #expect(isClose(cropRect.width, 900))
        #expect(cropRect.height == 1200)
    }

    @Test func landscapeTemplateRotatesAndPinsToLeadingEdge() {
        let layout = CameraGeometry.maskLayout(
            for: CGSize(width: 1600, height: 900),
            in: CGSize(width: 200, height: 600)
        )

        #expect(layout != nil)
        #expect(layout?.clockwiseQuarterTurns == 1)
        #expect(isClose(layout?.frame.minX ?? -1, 0))
        #expect(isClose(layout?.frame.minY ?? -1, 122.2222, tolerance: 0.01))
        #expect(isClose(layout?.frame.width ?? -1, 200, tolerance: 0.01))
        #expect(isClose(layout?.frame.height ?? -1, 355.5555, tolerance: 0.01))
    }

    @Test func portraitTemplatePinsToBottomEdge() {
        let layout = CameraGeometry.maskLayout(
            for: CGSize(width: 900, height: 1200),
            in: CGSize(width: 400, height: 700)
        )

        #expect(layout != nil)
        #expect(layout?.clockwiseQuarterTurns == 0)
        #expect(isClose(layout?.frame.minX ?? -1, 0))
        #expect(isClose(layout?.frame.minY ?? -1, 166.6667, tolerance: 0.01))
        #expect(isClose(layout?.frame.width ?? -1, 400, tolerance: 0.01))
        #expect(isClose(layout?.frame.height ?? -1, 533.3333, tolerance: 0.01))
    }

    @Test func interactiveCropStartsCenteredWhenNoOffsetApplied() {
        let cropRect = CameraGeometry.cropRect(
            for: CGSize(width: 400, height: 800),
            previewSize: CGSize(width: 100, height: 200),
            cropSize: CGSize(width: 100, height: 100),
            zoomScale: 1,
            offset: .zero
        )

        #expect(isClose(cropRect.origin.x, 0))
        #expect(isClose(cropRect.origin.y, 200))
        #expect(isClose(cropRect.width, 400))
        #expect(isClose(cropRect.height, 400))
    }

    @Test func interactiveCropRespectsZoomAndOffset() {
        let cropRect = CameraGeometry.cropRect(
            for: CGSize(width: 400, height: 800),
            previewSize: CGSize(width: 100, height: 200),
            cropSize: CGSize(width: 100, height: 100),
            zoomScale: 2,
            offset: CGSize(width: 25, height: -20)
        )

        #expect(isClose(cropRect.origin.x, 50))
        #expect(isClose(cropRect.origin.y, 340))
        #expect(isClose(cropRect.width, 200))
        #expect(isClose(cropRect.height, 200))
    }

    @Test func interactiveCropClampsToImageBounds() {
        let cropRect = CameraGeometry.cropRect(
            for: CGSize(width: 400, height: 800),
            previewSize: CGSize(width: 100, height: 200),
            cropSize: CGSize(width: 100, height: 100),
            zoomScale: 2,
            offset: CGSize(width: 300, height: 300)
        )

        #expect(isClose(cropRect.origin.x, 0))
        #expect(isClose(cropRect.origin.y, 0))
        #expect(isClose(cropRect.width, 200))
        #expect(isClose(cropRect.height, 200))
    }

#if canImport(UIKit)
    @Test func cropperOutputSizeCapsLargeCropRect() {
        let outputSize = CameraImageCropper.outputSize(
            for: CGRect(x: 0, y: 0, width: 5_000, height: 3_000),
            maximumLongEdge: 2_048
        )

        #expect(isClose(outputSize.width, 2_048, tolerance: 0.01))
        #expect(isClose(outputSize.height, 1_228.8, tolerance: 0.01))
    }

    @Test func cropperOutputSizeRejectsInvalidCropRect() {
        let outputSize = CameraImageCropper.outputSize(
            for: CGRect(x: 0, y: 0, width: CGFloat.infinity, height: 100),
            maximumLongEdge: 2_048
        )

        #expect(outputSize == .zero)
    }
#endif

    private func isClose(_ lhs: CGFloat, _ rhs: CGFloat, tolerance: CGFloat = 0.001) -> Bool {
        abs(lhs - rhs) <= tolerance
    }
}