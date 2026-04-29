#if os(iOS)
import SwiftUI
import UIKit

struct HeroImageView: View {
    let image: UIImage
    let maxHeight: CGFloat
    let namespace: Namespace.ID
    let geometryID: String
    let usesMatchedGeometry: Bool

    init(
        image: UIImage,
        maxHeight: CGFloat,
        namespace: Namespace.ID,
        geometryID: String,
        usesMatchedGeometry: Bool = true
    ) {
        self.image = image
        self.maxHeight = maxHeight
        self.namespace = namespace
        self.geometryID = geometryID
        self.usesMatchedGeometry = usesMatchedGeometry
    }

    var body: some View {
        Group {
            if usesMatchedGeometry {
                baseImage
                    .matchedGeometryEffect(id: geometryID, in: namespace)
            } else {
                baseImage
            }
        }
        .frame(maxWidth: .infinity, maxHeight: maxHeight, alignment: .top)
    }

    private var baseImage: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
    }
}
#endif
