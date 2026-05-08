import CoreGraphics

struct MomentCreationLiveOverlayLayout: Equatable {
    let frame: CGRect
    let contentSize: CGSize
    let rotationDegrees: Double
}

enum MomentCreationLiveOverlayLayoutResolver {
    static func resolve(
        imageSize: CGSize?,
        albumOrientation: MomentPhotoOrientation?,
        previewSize: CGSize
    ) -> MomentCreationLiveOverlayLayout? {
        let sourceSize = MomentPhotoLayoutResolver.displaySourceSize(
            imageSize: imageSize,
            albumOrientation: albumOrientation
        )

        guard let maskLayout = CameraGeometry.maskLayout(
            for: sourceSize,
            in: previewSize
        ) else {
            return nil
        }

        let isRotated = maskLayout.clockwiseQuarterTurns % 2 != 0
        let contentSize = if isRotated {
            CGSize(width: maskLayout.frame.height, height: maskLayout.frame.width)
        } else {
            maskLayout.frame.size
        }

        return MomentCreationLiveOverlayLayout(
            frame: maskLayout.frame,
            contentSize: contentSize,
            rotationDegrees: isRotated ? -maskLayout.rotationDegrees : maskLayout.rotationDegrees
        )
    }
}