import CoreGraphics

enum AlbumCardCoverLayout {
    static func fittedImageSize(for sourceSize: CGSize, in containerSize: CGSize) -> CGSize {
        guard sourceSize.width > 0,
              sourceSize.height > 0,
              containerSize.width > 0,
              containerSize.height > 0 else {
            return .zero
        }

        let sourceAspectRatio = sourceSize.width / sourceSize.height
        let containerAspectRatio = containerSize.width / containerSize.height

        if sourceAspectRatio > containerAspectRatio {
            let width = containerSize.width
            return CGSize(width: width, height: width / sourceAspectRatio)
        }

        let height = containerSize.height
        return CGSize(width: height * sourceAspectRatio, height: height)
    }
}