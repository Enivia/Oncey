#if canImport(UIKit)
import UIKit

enum AlbumTemplateResolver {
    static func resolve(for album: Album?, fallbackPhotoSize: CGSize) -> ExtractPhotoTemplate {
        let outlineImage: UIImage?
        if let path = album?.templateOutlinePath {
            outlineImage = ImageResourceService.platformImage(from: path)
        } else {
            outlineImage = nil
        }

        return ExtractPhotoTemplate(
            outlineImage: outlineImage,
            photoSize: album?.templatePhotoSize ?? fallbackPhotoSize
        )
    }
}
#endif