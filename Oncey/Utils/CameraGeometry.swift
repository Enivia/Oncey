import CoreGraphics

#if canImport(UIKit)
import UIKit
#endif

enum CameraCaptureAspect: String, CaseIterable, Identifiable, Codable, Sendable {
    case threeByFour
    case square
    case nineBySixteen

    var id: Self { self }

    var label: String {
        switch self {
        case .threeByFour:
            return "3:4"
        case .square:
            return "1:1"
        case .nineBySixteen:
            return "9:16"
        }
    }

    var aspectRatio: CGFloat {
        switch self {
        case .threeByFour:
            return 3 / 4
        case .square:
            return 1
        case .nineBySixteen:
            return 9 / 16
        }
    }

    var next: Self {
        let allCases = Self.allCases
        guard let index = allCases.firstIndex(of: self) else {
            return .threeByFour
        }

        let nextIndex = allCases.index(after: index)
        return nextIndex == allCases.endIndex ? allCases[allCases.startIndex] : allCases[nextIndex]
    }

    static func closest(to aspectRatio: CGFloat) -> Self {
        let candidates = Self.allCases.map { aspect in
            (aspect: aspect, distance: abs(aspect.aspectRatio - aspectRatio))
        }

        return candidates.min { $0.distance < $1.distance }?.aspect ?? .threeByFour
    }
}

struct CameraMaskLayout: Equatable {
    let frame: CGRect
    let clockwiseQuarterTurns: Int

    var rotationDegrees: Double {
        Double(clockwiseQuarterTurns) * 90
    }
}

struct CameraCaptureStageLayout: Equatable {
    let stageRect: CGRect
    let referenceRect: CGRect
    let frameRect: CGRect
    let maskSliderBottomY: CGFloat
    let captureControlsBottomY: CGFloat
}

enum CameraGeometry {
    static func captureStageLayout(
        stageWidth: CGFloat,
        aspect: CameraCaptureAspect,
        bottomInset: CGFloat
    ) -> CameraCaptureStageLayout {
        let safeStageWidth = max(stageWidth, 1)
        let safeBottomInset = max(bottomInset, 0)
        let stageHeight = safeStageWidth / CameraCaptureAspect.nineBySixteen.aspectRatio
        let referenceHeight = safeStageWidth / CameraCaptureAspect.threeByFour.aspectRatio
        let frameHeight = safeStageWidth / max(aspect.aspectRatio, 0.01)
        let stageRect = CGRect(x: 0, y: 0, width: safeStageWidth, height: stageHeight)
        let referenceRect = CGRect(
            x: 0,
            y: stageRect.minY,
            width: safeStageWidth,
            height: referenceHeight
        )

        let frameMinY: CGFloat
        switch aspect {
        case .square:
            frameMinY = referenceRect.minY + (referenceRect.height - frameHeight) / 2
        case .threeByFour:
            frameMinY = referenceRect.minY
        case .nineBySixteen:
            frameMinY = stageRect.minY
        }

        let frameRect = CGRect(
            x: 0,
            y: frameMinY,
            width: safeStageWidth,
            height: frameHeight
        )

        return CameraCaptureStageLayout(
            stageRect: stageRect,
            referenceRect: referenceRect,
            frameRect: frameRect,
            maskSliderBottomY: referenceRect.maxY - safeBottomInset,
            captureControlsBottomY: stageRect.maxY - safeBottomInset
        )
    }

    static func cropRect(for sourceSize: CGSize, aspect: CameraCaptureAspect) -> CGRect {
        cropRect(for: sourceSize, aspectRatio: aspect.aspectRatio)
    }

    static func cropRect(for sourceSize: CGSize, aspectRatio: CGFloat) -> CGRect {
        guard sourceSize.width > 0,
              sourceSize.height > 0,
              aspectRatio > 0 else {
            return .zero
        }

        let sourceAspectRatio = sourceSize.width / sourceSize.height

        if abs(sourceAspectRatio - aspectRatio) < 0.0001 {
            return CGRect(origin: .zero, size: sourceSize)
        }

        if sourceAspectRatio > aspectRatio {
            let cropWidth = sourceSize.height * aspectRatio
            let originX = (sourceSize.width - cropWidth) / 2
            return CGRect(x: originX, y: 0, width: cropWidth, height: sourceSize.height)
        }

        let cropHeight = sourceSize.width / aspectRatio
        let originY = (sourceSize.height - cropHeight) / 2
        return CGRect(x: 0, y: originY, width: sourceSize.width, height: cropHeight)
    }

    static func maskLayout(for templateSize: CGSize, in previewSize: CGSize) -> CameraMaskLayout? {
        guard templateSize.width > 0,
              templateSize.height > 0,
              previewSize.width > 0,
              previewSize.height > 0 else {
            return nil
        }

        let isLandscapeTemplate = templateSize.width > templateSize.height
        let displayedTemplateSize = isLandscapeTemplate
            ? CGSize(width: templateSize.height, height: templateSize.width)
            : templateSize
        let fittedSize = fittedSize(for: displayedTemplateSize, in: previewSize)

        if isLandscapeTemplate {
            return CameraMaskLayout(
                frame: CGRect(
                    x: 0,
                    y: (previewSize.height - fittedSize.height) / 2,
                    width: fittedSize.width,
                    height: fittedSize.height
                ),
                clockwiseQuarterTurns: 1
            )
        }

        return CameraMaskLayout(
            frame: CGRect(
                x: (previewSize.width - fittedSize.width) / 2,
                y: previewSize.height - fittedSize.height,
                width: fittedSize.width,
                height: fittedSize.height
            ),
            clockwiseQuarterTurns: 0
        )
    }

    static func fittedSize(for sourceSize: CGSize, in boundingSize: CGSize) -> CGSize {
        guard sourceSize.width > 0,
              sourceSize.height > 0,
              boundingSize.width > 0,
              boundingSize.height > 0 else {
            return .zero
        }

        let widthScale = boundingSize.width / sourceSize.width
        let heightScale = boundingSize.height / sourceSize.height
        let scale = min(widthScale, heightScale)

        return CGSize(
            width: sourceSize.width * scale,
            height: sourceSize.height * scale
        )
    }

    static func cropRect(
        for sourceSize: CGSize,
        previewSize: CGSize,
        cropSize: CGSize,
        zoomScale: CGFloat,
        offset: CGSize
    ) -> CGRect {
        guard sourceSize.width > 0,
              sourceSize.height > 0,
              previewSize.width > 0,
              previewSize.height > 0,
              cropSize.width > 0,
              cropSize.height > 0 else {
            return .zero
        }

        let safeZoomScale = max(zoomScale, 1)
        let baseCoverScale = max(cropSize.width / previewSize.width, cropSize.height / previewSize.height)
        let renderedWidth = previewSize.width * baseCoverScale * safeZoomScale
        let renderedHeight = previewSize.height * baseCoverScale * safeZoomScale

        guard renderedWidth > 0, renderedHeight > 0 else {
            return .zero
        }

        let visibleWidth = sourceSize.width * cropSize.width / renderedWidth
        let visibleHeight = sourceSize.height * cropSize.height / renderedHeight
        let centeredOriginX = (sourceSize.width - visibleWidth) / 2
        let centeredOriginY = (sourceSize.height - visibleHeight) / 2
        let translatedOriginX = centeredOriginX - (offset.width * sourceSize.width / renderedWidth)
        let translatedOriginY = centeredOriginY - (offset.height * sourceSize.height / renderedHeight)

        let maxOriginX = max(sourceSize.width - visibleWidth, 0)
        let maxOriginY = max(sourceSize.height - visibleHeight, 0)

        return CGRect(
            x: min(max(translatedOriginX, 0), maxOriginX),
            y: min(max(translatedOriginY, 0), maxOriginY),
            width: visibleWidth,
            height: visibleHeight
        )
    }
}

#if canImport(UIKit)
enum CameraImageCropper {
    static let maximumOutputLongEdge: CGFloat = 4_096

    static func croppedImage(_ image: UIImage, aspect: CameraCaptureAspect) -> UIImage {
        let normalizedImage = normalized(image)
        let cropRect = CameraGeometry.cropRect(for: normalizedImage.size, aspect: aspect)

        return croppedImage(normalizedImage, cropRect: cropRect)
    }

    static func croppedImage(
        _ image: UIImage,
        previewSize: CGSize,
        cropSize: CGSize,
        zoomScale: CGFloat,
        offset: CGSize
    ) -> UIImage {
        let normalizedImage = normalized(image)
        let cropRect = CameraGeometry.cropRect(
            for: normalizedImage.size,
            previewSize: previewSize,
            cropSize: cropSize,
            zoomScale: zoomScale,
            offset: offset
        )

        return croppedImage(normalizedImage, cropRect: cropRect)
    }

    private static func croppedImage(_ image: UIImage, cropRect: CGRect) -> UIImage {
        let normalizedCropRect = cropRect.standardized
        let outputSize = outputSize(for: normalizedCropRect)
        let coversWholeImage = normalizedCropRect.origin == .zero && normalizedCropRect.size == image.size

        guard normalizedCropRect.origin.x.isFinite,
              normalizedCropRect.origin.y.isFinite,
              outputSize.width > 0,
              outputSize.height > 0 else {
            return image
        }

        if coversWholeImage, outputSize == image.size {
            return image
        }

        let outputScale = min(
            outputSize.width / normalizedCropRect.width,
            outputSize.height / normalizedCropRect.height
        )

        let rendererFormat = UIGraphicsImageRendererFormat.default()
        rendererFormat.scale = 1
        rendererFormat.opaque = true

        let renderer = UIGraphicsImageRenderer(size: outputSize, format: rendererFormat)
        return renderer.image { _ in
            image.draw(
                in: CGRect(
                    x: -normalizedCropRect.origin.x * outputScale,
                    y: -normalizedCropRect.origin.y * outputScale,
                    width: image.size.width * outputScale,
                    height: image.size.height * outputScale
                )
            )
        }
    }

    static func outputSize(
        for cropRect: CGRect,
        maximumLongEdge: CGFloat = maximumOutputLongEdge
    ) -> CGSize {
        guard cropRect.width.isFinite,
              cropRect.height.isFinite,
              cropRect.width > 0,
              cropRect.height > 0,
              maximumLongEdge.isFinite,
              maximumLongEdge > 0 else {
            return .zero
        }

        let longEdge = max(cropRect.width, cropRect.height)
        let outputScale = min(maximumLongEdge / longEdge, 1)

        return CGSize(
            width: cropRect.width * outputScale,
            height: cropRect.height * outputScale
        )
    }

    static func normalized(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else {
            return image
        }

        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }
}
#endif