#if os(iOS)
import SwiftUI
import UIKit

struct HeroImageView: View {
    let image: UIImage
    let maxHeightRatio: CGFloat
    let namespace: Namespace.ID
    let geometryID: String

    private var maxHeight: CGFloat {
        let screenHeight = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .map { $0.screen.bounds.height }
            .first ?? 800

        return screenHeight * maxHeightRatio
    }

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .matchedGeometryEffect(id: geometryID, in: namespace)
            .frame(maxWidth: .infinity)
            .frame(maxHeight: maxHeight, alignment: .top)
    }
}
#endif
