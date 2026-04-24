#if canImport(UIKit)
import SwiftUI
import UIKit

struct OutlineMaskImageView: View {
    let image: UIImage
    var opacity: Double = 1
    var expansion: CGFloat = 1.2

    private let offsets: [CGSize] = [
        CGSize(width: -1, height: 0),
        CGSize(width: 1, height: 0),
        CGSize(width: 0, height: -1),
        CGSize(width: 0, height: 1),
        CGSize(width: -1, height: -1),
        CGSize(width: 1, height: -1),
        CGSize(width: -1, height: 1),
        CGSize(width: 1, height: 1)
    ]

    var body: some View {
        ZStack {
            ForEach(Array(offsets.enumerated()), id: \.offset) { _, offset in
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .offset(x: offset.width * expansion, y: offset.height * expansion)
                    .opacity(opacity * 0.18)
            }

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .opacity(opacity)
        }
        .compositingGroup()
    }
}
#endif