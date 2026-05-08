import CoreGraphics
import Testing
@testable import Oncey

struct MomentPhotoLayoutResolverTests {

    @Test func initialAspectStaysInThreeByFourFamily() {
        #expect(
            MomentPhotoLayoutResolver.initialAspect(
                latestMomentPhotoSize: CGSize(width: 900, height: 1200)
            ) == .threeByFour
        )
    }

    @Test func initialOrientationPrefersAlbumOrientationWhenAvailable() {
        #expect(
            MomentPhotoLayoutResolver.initialOrientation(
                albumOrientation: .landscape,
                latestMomentPhotoSize: CGSize(width: 900, height: 1200)
            ) == .landscape
        )
    }

    @Test func initialOrientationFallsBackToLatestMomentPhotoSize() {
        #expect(
            MomentPhotoLayoutResolver.initialOrientation(
                albumOrientation: nil,
                latestMomentPhotoSize: CGSize(width: 1600, height: 900)
            ) == .landscape
        )
    }

    @Test func displayAspectRatioPrefersActualImageSize() {
        #expect(
            MomentPhotoLayoutResolver.displayAspectRatio(
                imageSize: CGSize(width: 1600, height: 900),
                albumOrientation: .portrait
            ) == 1600 / 900
        )
    }

    @Test func displayAspectRatioFallsBackToLandscapeAlbumOrientation() {
        #expect(
            MomentPhotoLayoutResolver.displayAspectRatio(
                imageSize: nil,
                albumOrientation: .landscape
            ) == 4 / 3
        )
    }

    @Test func displaySourceSizeFallsBackToPortraitThreeByFour() {
        #expect(
            MomentPhotoLayoutResolver.displaySourceSize(
                imageSize: nil,
                albumOrientation: nil
            ) == CGSize(width: 3 / 4, height: 1)
        )
    }
}