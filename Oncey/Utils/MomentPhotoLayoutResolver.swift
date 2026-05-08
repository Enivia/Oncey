import CoreGraphics

enum MomentPhotoLayoutResolver {
    static func initialAspect(
        albumRatio: CameraCaptureAspect?,
        latestMomentPhotoSize: CGSize?
    ) -> CameraCaptureAspect {
        if let albumRatio {
            return albumRatio
        }

        if let latestMomentPhotoSize,
           latestMomentPhotoSize.width > 0,
           latestMomentPhotoSize.height > 0 {
            return CameraCaptureAspect.closest(to: latestMomentPhotoSize.width / latestMomentPhotoSize.height)
        }

        return .threeByFour
    }

    static func initialOrientation(
        latestMomentPhotoOrientation: MomentPhotoOrientation?,
        latestMomentPhotoSize: CGSize?
    ) -> MomentPhotoOrientation {
        if let latestMomentPhotoOrientation {
            return latestMomentPhotoOrientation
        }

        if let latestMomentPhotoSize,
           latestMomentPhotoSize.width > 0,
           latestMomentPhotoSize.height > 0 {
            return .inferred(from: latestMomentPhotoSize)
        }

        return .portrait
    }

    static func displayAspectRatio(
        imageSize: CGSize?,
        albumRatio: CameraCaptureAspect?,
        photoOrientation: MomentPhotoOrientation
    ) -> CGFloat {
        if let imageSize,
           imageSize.width > 0,
           imageSize.height > 0 {
            return imageSize.width / imageSize.height
        }

        if let albumRatio {
            return albumRatio.aspectRatio(for: photoOrientation)
        }

        return CameraCaptureAspect.threeByFour.aspectRatio(for: photoOrientation)
    }

    static func displaySourceSize(
        imageSize: CGSize?,
        albumRatio: CameraCaptureAspect?,
        photoOrientation: MomentPhotoOrientation
    ) -> CGSize {
        if let imageSize,
           imageSize.width > 0,
           imageSize.height > 0 {
            return imageSize
        }

        return CGSize(
            width: displayAspectRatio(
                imageSize: nil,
                albumRatio: albumRatio,
                photoOrientation: photoOrientation
            ),
            height: 1
        )
    }
}
