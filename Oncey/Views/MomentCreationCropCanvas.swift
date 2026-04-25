#if os(iOS)
import SwiftUI
import UIKit

struct MomentCreationCropCanvas: View {
    let image: UIImage
    let containerSize: CGSize
    let previewSize: CGSize
    let cropSize: CGSize

    @Binding var zoomScale: CGFloat
    @Binding var committedZoomScale: CGFloat
    @Binding var offset: CGSize
    @Binding var committedOffset: CGSize

    var body: some View {
        ZStack {
            transformedPreviewImage(opacity: 0.24)

            ZStack {
                transformedPreviewImage()

                Rectangle()
                    .stroke(Color.white.opacity(0.92), lineWidth: 2)
            }
            .frame(width: cropSize.width, height: cropSize.height)
            .clipped(antialiased: false)
            .shadow(color: .black.opacity(0.28), radius: 18, y: 10)
        }
        .frame(width: containerSize.width, height: containerSize.height)
        .contentShape(Rectangle())
        .gesture(dragGesture)
        .simultaneousGesture(magnificationGesture)
    }

    private func transformedPreviewImage(opacity: Double = 1) -> some View {
        Image(uiImage: image)
            .resizable()
            .frame(width: previewSize.width, height: previewSize.height)
            .scaleEffect(baseCoverScale * zoomScale)
            .offset(clampedOffset(for: offset, zoom: zoomScale))
            .opacity(opacity)
            .frame(width: containerSize.width, height: containerSize.height)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let proposedOffset = CGSize(
                    width: committedOffset.width + value.translation.width,
                    height: committedOffset.height + value.translation.height
                )
                offset = clampedOffset(for: proposedOffset, zoom: zoomScale)
            }
            .onEnded { _ in
                committedOffset = offset
            }
    }

    private var magnificationGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let proposedScale = max(1, committedZoomScale * value.magnification)
                zoomScale = proposedScale
                offset = clampedOffset(for: offset, zoom: proposedScale)
            }
            .onEnded { _ in
                committedZoomScale = zoomScale
                committedOffset = offset
            }
    }

    private var baseCoverScale: CGFloat {
        max(cropSize.width / previewSize.width, cropSize.height / previewSize.height)
    }

    private func clampedOffset(for proposedOffset: CGSize, zoom: CGFloat) -> CGSize {
        let renderedWidth = previewSize.width * baseCoverScale * zoom
        let renderedHeight = previewSize.height * baseCoverScale * zoom
        let horizontalLimit = max(0, (renderedWidth - cropSize.width) / 2)
        let verticalLimit = max(0, (renderedHeight - cropSize.height) / 2)

        return CGSize(
            width: min(max(proposedOffset.width, -horizontalLimit), horizontalLimit),
            height: min(max(proposedOffset.height, -verticalLimit), verticalLimit)
        )
    }
}
#endif
