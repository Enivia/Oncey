import CoreGraphics
import Testing
@testable import Oncey

struct AlbumCardCoverLayoutTests {
    @Test func fittedImageSizeMatchesContainerWhenAspectRatiosMatch() {
        let size = AlbumCardCoverLayout.fittedImageSize(
            for: CGSize(width: 4000, height: 3000),
            in: CGSize(width: 320, height: 240)
        )

        #expect(size.width == 320)
        #expect(size.height == 240)
    }

    @Test func fittedImageSizeCentersPortraitImageWithinFourByThreeContainer() {
        let size = AlbumCardCoverLayout.fittedImageSize(
            for: CGSize(width: 3000, height: 4000),
            in: CGSize(width: 320, height: 240)
        )

        #expect(size.width == 180)
        #expect(size.height == 240)
    }

    @Test func fittedImageSizeLimitsWideImageByContainerWidth() {
        let size = AlbumCardCoverLayout.fittedImageSize(
            for: CGSize(width: 4000, height: 2000),
            in: CGSize(width: 320, height: 240)
        )

        #expect(size.width == 320)
        #expect(size.height == 160)
    }
}