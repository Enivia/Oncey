#if canImport(UIKit)
import CoreGraphics
import UIKit

struct ExtractPhotoTemplate {
    let outlineImage: UIImage?
    let photoSize: CGSize

    var aspectRatio: CGFloat {
        guard photoSize.height > 0 else {
            return 1
        }

        return photoSize.width / photoSize.height
    }

    func exportSize(longEdge: CGFloat = 2_048) -> CGSize {
        let safeWidth = max(photoSize.width, 1)
        let safeHeight = max(photoSize.height, 1)
        let longestDimension = max(safeWidth, safeHeight)
        let scale = longEdge / longestDimension

        return CGSize(width: safeWidth * scale, height: safeHeight * scale)
    }
}

struct ExtractPhotoAlbumResult {
    let image: UIImage
    let templateDraft: AlbumTemplateOutlineDraft
}

enum ExtractPhotoMode {
    case albumTemplate
    case momentCrop(template: ExtractPhotoTemplate)
}

enum ExtractPhotoOutput {
    case albumTemplate(ExtractPhotoAlbumResult)
    case croppedMomentImage(UIImage)
}
#endif