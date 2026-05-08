import CoreGraphics
import Testing
@testable import Oncey

struct MomentCreationPhotoOrientationResolverTests {
    @Test func resolvesLandscapeFromCapturedImageWhenAlbumHasNoOrientation() {
        let resolvedOrientation = MomentCreationPhotoOrientationResolver.resolve(
            albumOrientation: nil,
            imageSize: CGSize(width: 1_920, height: 1_080)
        )

        #expect(resolvedOrientation == .landscape)
    }

    @Test func preservesAlbumOrientationWhenPresent() {
        let resolvedOrientation = MomentCreationPhotoOrientationResolver.resolve(
            albumOrientation: .portrait,
            imageSize: CGSize(width: 1_920, height: 1_080)
        )

        #expect(resolvedOrientation == .portrait)
    }

    @Test func fallsBackToPortraitWithoutAlbumOrImageSize() {
        let resolvedOrientation = MomentCreationPhotoOrientationResolver.resolve(
            albumOrientation: nil,
            imageSize: nil
        )

        #expect(resolvedOrientation == .portrait)
    }
}