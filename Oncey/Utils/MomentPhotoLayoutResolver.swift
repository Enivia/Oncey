import CoreGraphics

enum MomentPhotoLayoutResolver {
    static func initialAspect(
        latestMomentPhotoSize: CGSize?
    ) -> CameraCaptureAspect {
        if let latestMomentPhotoSize,
           latestMomentPhotoSize.width > 0,
           latestMomentPhotoSize.height > 0 {
            return .threeByFour
        }

        return .threeByFour
    }

    static func initialOrientation(
        albumOrientation: MomentPhotoOrientation?,
        latestMomentPhotoSize: CGSize?
    ) -> MomentPhotoOrientation {
        if let albumOrientation {
            return albumOrientation
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
        albumOrientation: MomentPhotoOrientation?
    ) -> CGFloat {
        if let imageSize,
           imageSize.width > 0,
           imageSize.height > 0 {
            return imageSize.width / imageSize.height
        }

        if albumOrientation?.isLandscape == true {
            return 4 / 3
        }

        return 3 / 4
    }

    static func displaySourceSize(
        imageSize: CGSize?,
        albumOrientation: MomentPhotoOrientation?
    ) -> CGSize {
        if let imageSize,
           imageSize.width > 0,
           imageSize.height > 0 {
            return imageSize
        }

        return CGSize(
            width: displayAspectRatio(
                imageSize: nil,
                albumOrientation: albumOrientation
            ),
            height: 1
        )
    }
}
