#if canImport(UIKit)
import SwiftUI
import UIKit

struct PhotoCropView: View {
    let image: UIImage
    let onConfirm: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var aspectRatio: CropAspectRatio = .square
    @State private var zoomScale: CGFloat = 1
    @State private var committedZoomScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var committedOffset: CGSize = .zero
    @State private var quarterTurns = 0

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let cropSize = aspectRatio.cropSize(in: proxy.size)

                VStack(spacing: 28) {
                    Spacer(minLength: 20)

                    cropCanvas(cropSize: cropSize)

                    VStack(spacing: 18) {
                        Text("Pinch to zoom and drag to adjust the crop.")
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(.white.opacity(0.72))

                        HStack(spacing: 12) {
                            ForEach(CropAspectRatio.allCases) { ratio in
                                Button(ratio.label) {
                                    setAspectRatio(ratio, containerSize: proxy.size)
                                }
                                .buttonStyle(CropRatioButtonStyle(isSelected: ratio == aspectRatio))
                            }
                        }

                        Button {
                            rotateClockwise(cropSize: cropSize)
                        } label: {
                            Label("Rotate", systemImage: "rotate.right.fill")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.16))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer(minLength: 20)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 20)
                .background(Color.black.ignoresSafeArea())
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Back", systemImage: "chevron.backward") {
                            dismiss()
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Confirm") {
                            onConfirm(exportCroppedImage(previewCropSize: cropSize))
                            dismiss()
                        }
                        .fontWeight(.semibold)
                    }
                }
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbarBackground(.hidden, for: .navigationBar)
            }
        }
    }

    private var previewImageSize: CGSize {
        image.size.scaledToFit(maxDimension: 320)
    }

    private var rotationAngle: Angle {
        .degrees(Double(quarterTurns) * 90)
    }

    @ViewBuilder
    private func cropCanvas(cropSize: CGSize) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.white.opacity(0.08))

            Image(uiImage: image)
                .resizable()
                .frame(width: previewImageSize.width, height: previewImageSize.height)
                .scaleEffect(baseCoverScale(for: cropSize) * zoomScale)
                .rotationEffect(rotationAngle)
                .offset(clampedOffset(for: cropSize))
                .gesture(dragGesture(cropSize: cropSize))
                .simultaneousGesture(magnificationGesture(cropSize: cropSize))
        }
        .frame(width: cropSize.width, height: cropSize.height)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.9), lineWidth: 2)
        }
        .shadow(color: .black.opacity(0.3), radius: 18, y: 10)
    }

    private func dragGesture(cropSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let proposedOffset = CGSize(
                    width: committedOffset.width + value.translation.width,
                    height: committedOffset.height + value.translation.height
                )
                offset = clampedOffset(for: cropSize, proposed: proposedOffset)
            }
            .onEnded { _ in
                committedOffset = offset
            }
    }

    private func magnificationGesture(cropSize: CGSize) -> some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let proposedScale = max(1, committedZoomScale * value.magnification)
                zoomScale = proposedScale
                offset = clampedOffset(for: cropSize, proposed: offset, zoom: proposedScale)
            }
            .onEnded { _ in
                committedZoomScale = zoomScale
                committedOffset = offset
            }
    }

    private func setAspectRatio(_ ratio: CropAspectRatio, containerSize: CGSize) {
        aspectRatio = ratio
        let nextCropSize = ratio.cropSize(in: containerSize)
        offset = clampedOffset(for: nextCropSize)
        committedOffset = offset
    }

    private func rotateClockwise(cropSize: CGSize) {
        quarterTurns = (quarterTurns + 1) % 4
        offset = clampedOffset(for: cropSize)
        committedOffset = offset
    }

    private func baseCoverScale(for cropSize: CGSize) -> CGFloat {
        let rotatedPreviewSize = rotatedSize(for: previewImageSize)
        return max(cropSize.width / rotatedPreviewSize.width, cropSize.height / rotatedPreviewSize.height)
    }

    private func rotatedSize(for size: CGSize) -> CGSize {
        if quarterTurns.isMultiple(of: 2) {
            return size
        }

        return CGSize(width: size.height, height: size.width)
    }

    private func clampedOffset(
        for cropSize: CGSize,
        proposed: CGSize? = nil,
        zoom: CGFloat? = nil
    ) -> CGSize {
        let proposedOffset = proposed ?? offset
        let currentZoom = zoom ?? zoomScale
        let rotatedPreviewSize = rotatedSize(for: previewImageSize)
        let renderedWidth = rotatedPreviewSize.width * baseCoverScale(for: cropSize) * currentZoom
        let renderedHeight = rotatedPreviewSize.height * baseCoverScale(for: cropSize) * currentZoom

        let horizontalLimit = max(0, (renderedWidth - cropSize.width) / 2)
        let verticalLimit = max(0, (renderedHeight - cropSize.height) / 2)

        return CGSize(
            width: min(max(proposedOffset.width, -horizontalLimit), horizontalLimit),
            height: min(max(proposedOffset.height, -verticalLimit), verticalLimit)
        )
    }

    private func exportCroppedImage(previewCropSize: CGSize) -> UIImage {
        let outputSize = aspectRatio.exportSize()
        let translation = clampedOffset(for: previewCropSize)
        let normalizedImage = normalizedImage(image)
        let rotatedSourceSize = quarterTurns.isMultiple(of: 2)
            ? normalizedImage.size
            : CGSize(width: normalizedImage.size.height, height: normalizedImage.size.width)
        let baseScale = max(outputSize.width / rotatedSourceSize.width, outputSize.height / rotatedSourceSize.height)
        let outputTranslation = CGSize(
            width: (translation.width / previewCropSize.width) * outputSize.width,
            height: (translation.height / previewCropSize.height) * outputSize.height
        )

        let rendererFormat = UIGraphicsImageRendererFormat.default()
        rendererFormat.opaque = true
        rendererFormat.scale = 1

        let renderer = UIGraphicsImageRenderer(size: outputSize, format: rendererFormat)
        return renderer.image { context in
            let cgContext = context.cgContext
            cgContext.setFillColor(UIColor.black.cgColor)
            cgContext.fill(CGRect(origin: .zero, size: outputSize))
            cgContext.interpolationQuality = .high
            cgContext.translateBy(
                x: outputSize.width / 2 + outputTranslation.width,
                y: outputSize.height / 2 + outputTranslation.height
            )
            cgContext.rotate(by: CGFloat(quarterTurns) * (.pi / 2))
            cgContext.scaleBy(x: baseScale * zoomScale, y: baseScale * zoomScale)

            normalizedImage.draw(
                in: CGRect(
                    x: -normalizedImage.size.width / 2,
                    y: -normalizedImage.size.height / 2,
                    width: normalizedImage.size.width,
                    height: normalizedImage.size.height
                )
            )
        }
    }

    private func normalizedImage(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else {
            return image
        }

        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }
}

private struct CropRatioButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(isSelected ? Color.black : Color.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? Color.white : Color.white.opacity(configuration.isPressed ? 0.24 : 0.14))
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

private extension CGSize {
    func scaledToFit(maxDimension: CGFloat) -> CGSize {
        let longestEdge = max(width, height)
        guard longestEdge > 0 else {
            return CGSize(width: maxDimension, height: maxDimension)
        }

        let scale = maxDimension / longestEdge
        return CGSize(width: width * scale, height: height * scale)
    }
}
#endif