import CoreGraphics

enum MomentCreationPhotoOrientationResolver {
    static func resolve(
        albumOrientation: MomentPhotoOrientation?,
        imageSize: CGSize?
    ) -> MomentPhotoOrientation {
        if let albumOrientation {
            return albumOrientation
        }

        if let imageSize,
           imageSize.width > 0,
           imageSize.height > 0 {
            return .inferred(from: imageSize)
        }

        return .portrait
    }
}