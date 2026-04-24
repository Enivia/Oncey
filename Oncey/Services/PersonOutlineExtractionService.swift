#if canImport(UIKit) && canImport(Vision)
import CoreImage
import CoreVideo
import ImageIO
import UIKit
import Vision

struct AlbumTemplateOutlineDraft {
    let photoSize: CGSize
    let outlineImage: UIImage?

    var photoAspectRatio: Double? {
        guard photoSize.height > 0 else {
            return nil
        }

        return photoSize.width / photoSize.height
    }

    var hasOutline: Bool {
        outlineImage != nil
    }
}

enum PersonOutlineExtractionService {
    typealias OutlineGenerator = @Sendable (_ image: CGImage, _ orientation: CGImagePropertyOrientation) async throws -> CGImage?

    struct Pipeline {
        let personInstance: OutlineGenerator
        let foregroundInstance: OutlineGenerator
        let personSegmentation: OutlineGenerator
    }

    nonisolated
    static func extract(
        from image: UIImage,
        pipeline: Pipeline? = nil
    ) async -> AlbumTemplateOutlineDraft {
        let normalizedImage = normalized(image)
        let photoSize = normalizedImage.size
        let pipeline = pipeline ?? Pipeline(
            personInstance: generatePersonInstanceOutline,
            foregroundInstance: generateForegroundInstanceOutline,
            personSegmentation: generatePersonSegmentationOutline
        )

        guard let cgImage = normalizedImage.cgImage else {
            return AlbumTemplateOutlineDraft(photoSize: photoSize, outlineImage: nil)
        }

        do {
            let outlineCGImage = try await generateOutlineMask(
                from: cgImage,
                orientation: .up,
                pipeline: pipeline
            )
            let outlineImage = outlineCGImage.map {
                UIImage(cgImage: $0, scale: normalizedImage.scale, orientation: .up)
            }

            return AlbumTemplateOutlineDraft(photoSize: photoSize, outlineImage: outlineImage)
        } catch {
            return AlbumTemplateOutlineDraft(photoSize: photoSize, outlineImage: nil)
        }
    }

    @available(iOS 18.0, *)
    nonisolated
    private static func generateOutlineMask(
        from image: CGImage,
        orientation: CGImagePropertyOrientation,
        pipeline: Pipeline
    ) async throws -> CGImage? {
        if let outline = try? await pipeline.personInstance(image, orientation) {
            return outline
        }

        if let outline = try? await pipeline.foregroundInstance(image, orientation) {
            return outline
        }

        if let outline = try? await pipeline.personSegmentation(image, orientation) {
            return outline
        }

        return nil
    }

    @available(iOS 18.0, *)
    nonisolated
    private static func generatePersonInstanceOutline(
        from image: CGImage,
        orientation: CGImagePropertyOrientation
    ) async throws -> CGImage? {
        let request = GeneratePersonInstanceMaskRequest()
        let observation = try await request.perform(on: image, orientation: orientation)

        guard let observation, !observation.allInstances.isEmpty else {
            return nil
        }

        let handler = ImageRequestHandler(image, orientation: orientation)
        let scaledMask = try observation.generateScaledMask(
            for: observation.allInstances,
            scaledToImageFrom: handler
        )

        return renderOutline(from: CIImage(cvPixelBuffer: scaledMask))
    }

    @available(iOS 18.0, *)
    nonisolated
    private static func generateForegroundInstanceOutline(
        from image: CGImage,
        orientation: CGImagePropertyOrientation
    ) async throws -> CGImage? {
        let request = GenerateForegroundInstanceMaskRequest()
        let observation = try await request.perform(on: image, orientation: orientation)

        guard let observation, !observation.allInstances.isEmpty else {
            return nil
        }

        let handler = ImageRequestHandler(image, orientation: orientation)
        let scaledMask = try observation.generateScaledMask(
            for: observation.allInstances,
            scaledToImageFrom: handler
        )

        return renderOutline(from: CIImage(cvPixelBuffer: scaledMask))
    }

    @available(iOS 18.0, *)
    nonisolated
    private static func generatePersonSegmentationOutline(
        from image: CGImage,
        orientation: CGImagePropertyOrientation
    ) async throws -> CGImage? {
        let request = GeneratePersonSegmentationRequest()
        request.qualityLevel = .balanced
        request.outputPixelFormatType = kCVPixelFormatType_OneComponent8
        let observation = try await request.perform(on: image, orientation: orientation)
        let maskImage = try observation.cgImage
        return renderOutline(from: CIImage(cgImage: maskImage))
    }

    nonisolated
    private static func renderOutline(from maskImage: CIImage) -> CGImage? {
        let extent = maskImage.extent.integral
        guard !extent.isEmpty else {
            return nil
        }

        let edgeMask = maskImage
            .applyingFilter("CIEdges", parameters: [kCIInputIntensityKey: 10.0])
            .applyingFilter("CIMaskToAlpha")
            .applyingFilter("CIMorphologyMaximum", parameters: [kCIInputRadiusKey: 2.0])
        let foreground = CIImage(color: CIColor(red: 1, green: 1, blue: 1, alpha: 0.96))
            .cropped(to: extent)
        let background = CIImage(color: CIColor(red: 0, green: 0, blue: 0, alpha: 0))
            .cropped(to: extent)
        let outlined = foreground.applyingFilter(
            "CIBlendWithAlphaMask",
            parameters: [
                kCIInputBackgroundImageKey: background,
                kCIInputMaskImageKey: edgeMask
            ]
        )

        return CIContext().createCGImage(outlined, from: extent)
    }

    nonisolated
    private static func normalized(_ image: UIImage) -> UIImage {
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