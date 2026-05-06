import CoreGraphics
import Testing
@testable import Oncey

struct MomentPhotoLayoutResolverTests {

    @Test func initialAspectPrefersAlbumRatioWhenAvailable() {
        #expect(
            MomentPhotoLayoutResolver.initialAspect(
                albumRatio: .square,
                templatePhotoSize: CGSize(width: 1600, height: 900),
                latestMomentPhotoSize: CGSize(width: 900, height: 1200)
            ) == .square
        )
    }

    @Test func initialAspectTreatsLandscapeTemplateAsSameAspectFamily() {
        #expect(
            MomentPhotoLayoutResolver.initialAspect(
                albumRatio: nil,
                templatePhotoSize: CGSize(width: 1600, height: 900),
                latestMomentPhotoSize: nil
            ) == .nineBySixteen
        )
    }

    @Test func initialOrientationPrefersStoredMomentOrientation() {
        #expect(
            MomentPhotoLayoutResolver.initialOrientation(
                templatePhotoSize: CGSize(width: 900, height: 1200),
                latestMomentPhotoOrientation: .landscape,
                latestMomentPhotoSize: CGSize(width: 900, height: 1200)
            ) == .landscape
        )
    }

    @Test func initialOrientationFallsBackToTemplatePhotoSize() {
        #expect(
            MomentPhotoLayoutResolver.initialOrientation(
                templatePhotoSize: CGSize(width: 1600, height: 900),
                latestMomentPhotoOrientation: nil,
                latestMomentPhotoSize: CGSize(width: 900, height: 1200)
            ) == .landscape
        )
    }

    @Test func initialOrientationFallsBackToLatestMomentPhotoSize() {
        #expect(
            MomentPhotoLayoutResolver.initialOrientation(
                templatePhotoSize: nil,
                latestMomentPhotoOrientation: nil,
                latestMomentPhotoSize: CGSize(width: 1600, height: 900)
            ) == .landscape
        )
    }

    @Test func displayAspectRatioPrefersActualImageSize() {
        #expect(
            MomentPhotoLayoutResolver.displayAspectRatio(
                imageSize: CGSize(width: 1600, height: 900),
                albumRatio: .threeByFour,
                photoOrientation: .portrait
            ) == 1600 / 900
        )
    }

    @Test func displayAspectRatioFallsBackToLandscapeAlbumRatio() {
        #expect(
            MomentPhotoLayoutResolver.displayAspectRatio(
                imageSize: nil,
                albumRatio: .threeByFour,
                photoOrientation: .landscape
            ) == 4 / 3
        )
    }
}