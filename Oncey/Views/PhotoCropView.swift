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

                ZStack {
                    Color.black.ignoresSafeArea()

                    cropCanvas(cropSize: cropSize)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    bottomToolbar(containerSize: proxy.size, cropSize: cropSize)
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Back", systemImage: "chevron.backward") {
                            dismiss()
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            onConfirm(exportCroppedImage(previewCropSize: cropSize))
                            dismiss()
                        } label: {
                            Image(systemName: "checkmark")
                        }
                        .accessibilityLabel("Confirm")
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
            transformedPreviewImage(for: cropSize, opacity: 0.3)

            transformedPreviewImage(for: cropSize)
                .compositingGroup()
                .clipped(antialiased: false)

            Rectangle()
                .stroke(Color.white.opacity(0.92), lineWidth: 2)
        }
        .frame(width: cropSize.width, height: cropSize.height)
        .contentShape(Rectangle())
        .gesture(dragGesture(cropSize: cropSize))
        .simultaneousGesture(magnificationGesture(cropSize: cropSize))
        .shadow(color: .black.opacity(0.3), radius: 18, y: 10)
    }

    private func transformedPreviewImage(for cropSize: CGSize, opacity: Double = 1) -> some View {
        Image(uiImage: image)
            .resizable()
            .frame(width: previewImageSize.width, height: previewImageSize.height)
            .scaleEffect(baseCoverScale(for: cropSize) * zoomScale)
            .rotationEffect(rotationAngle)
            .offset(clampedOffset(for: cropSize))
            .frame(width: cropSize.width, height: cropSize.height)
            .opacity(opacity)
    }

    private func bottomToolbar(containerSize: CGSize, cropSize: CGSize) -> some View {
        HStack(spacing: 0) {
            Button {
                rotateClockwise(cropSize: cropSize)
            } label: {
                Image(systemName: "rotate.right")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.86))
                    .frame(width: 72)
                    .frame(maxHeight: .infinity)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Rotate")

            toolbarDivider

            HStack(spacing: 0) {
                ForEach(CropAspectRatio.allCases) { ratio in
                    Button {
                        setAspectRatio(ratio, containerSize: containerSize)
                    } label: {
                        CropRatioButtonLabel(ratio: ratio, isSelected: ratio == aspectRatio)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityLabel("Crop ratio \(ratio.label)")
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 92)
        .padding(.horizontal, AppTheme.Spacing.s2)
        .padding(.top, AppTheme.Spacing.s2)
        .padding(.bottom, AppTheme.Spacing.s4)
    }

    private var toolbarDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.12))
            .frame(width: 1)
            .padding(.vertical, AppTheme.Spacing.s3)
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

private struct CropRatioButtonLabel: View {
    let ratio: CropAspectRatio
    let isSelected: Bool

    private var selectionColor: Color {
        isSelected ? AppTheme.Colors.accent : Color.white.opacity(0.6)
    }

    private var labelColor: Color {
        isSelected ? AppTheme.Colors.accent : Color.white.opacity(0.74)
    }

    private var sampleSize: CGSize {
        AppTheme.Layout.fittedSize(for: ratio.dimensions, maxSize: CGSize(width: 28, height: 28))
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.s1) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .stroke(selectionColor, lineWidth: 2)
                .background(isSelected ? AppTheme.Colors.accentSoft : Color.clear)
                .frame(width: sampleSize.width, height: sampleSize.height)
                .frame(width: 40, height: 40)

            Text(ratio.label)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(labelColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
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

#Preview {
    let image = UIGraphicsImageRenderer(size: CGSize(width: 800, height: 600)).image { ctx in
        let stops: [(UIColor, CGFloat)] = [
            (.systemIndigo, 0),
            (.systemPurple, 0.5),
            (.systemPink, 1)
        ]
        let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: stops.map(\.0.cgColor) as CFArray,
            locations: stops.map(\.1)
        )!
        ctx.cgContext.drawLinearGradient(
            gradient,
            start: CGPoint(x: 0, y: 0),
            end: CGPoint(x: 800, y: 600),
            options: []
        )
    }

    PhotoCropView(image: image) { _ in }
}
#endif
