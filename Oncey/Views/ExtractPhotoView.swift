#if canImport(UIKit)
import SwiftUI
import UIKit

struct ExtractPhotoView: View {
    let image: UIImage
    let mode: ExtractPhotoMode
    let onConfirm: (ExtractPhotoOutput) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var showsOutline = true
    @State private var extractedTemplateDraft: AlbumTemplateOutlineDraft?
    @State private var isExtractingTemplate = false
    @State private var zoomScale: CGFloat = 1
    @State private var committedZoomScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var committedOffset: CGSize = .zero
    @State private var quarterTurns = 0

    init(image: UIImage, mode: ExtractPhotoMode, onConfirm: @escaping (ExtractPhotoOutput) -> Void) {
        self.image = Self.normalized(image)
        self.mode = mode
        self.onConfirm = onConfirm
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let previewSize = previewSize(for: proxy.size.width)
                let cropSize = cropSize(in: previewSize)

                ZStack {
                    Color.black.ignoresSafeArea()

                    VStack(spacing: 0) {
                        contentArea(previewSize: previewSize, cropSize: cropSize)

                        if showsCropControls {
                            bottomToolbar(
                                previewSize: previewSize,
                                cropSize: cropSize,
                                bottomInset: proxy.safeAreaInsets.bottom
                            )
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Close", systemImage: "xmark") {
                            dismiss()
                        }
                    }

                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button {
                            showsOutline.toggle()
                        } label: {
                            Image(systemName: showsOutline ? "square.stack.3d.up.fill" : "square.stack.3d.up")
                        }
                        .disabled(!canToggleOutline)
                        .accessibilityLabel(showsOutline ? "Hide outline" : "Show outline")

                        Button {
                            confirm(previewSize: previewSize, cropSize: cropSize)
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
        .onAppear {
            prepareAlbumTemplateIfNeeded()
        }
        .onDisappear {
            if case .albumTemplate = mode {
                isExtractingTemplate = false
            }
        }
    }

    private var showsCropControls: Bool {
        if case .momentCrop = mode {
            return true
        }

        return false
    }

    private var canToggleOutline: Bool {
        outlineImage != nil
    }

    private var outlineImage: UIImage? {
        switch mode {
        case .albumTemplate:
            return extractedTemplateDraft?.outlineImage
        case .momentCrop(let template):
            return template.outlineImage
        }
    }

    private var rotationAngle: Angle {
        .degrees(Double(quarterTurns) * 90)
    }

    @ViewBuilder
    private func contentArea(previewSize: CGSize, cropSize: CGSize) -> some View {
        switch mode {
        case .albumTemplate:
            GeometryReader { contentProxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: AppTheme.Spacing.s4) {
                        Spacer(minLength: 0)

                        previewArea(previewSize: previewSize, cropSize: cropSize)
                            .frame(maxWidth: .infinity)

                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: contentProxy.size.height)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .momentCrop:
            VStack(spacing: AppTheme.Spacing.s4) {
                Spacer(minLength: 0)
                previewArea(previewSize: previewSize, cropSize: cropSize)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private func previewArea(previewSize: CGSize, cropSize: CGSize) -> some View {
        switch mode {
        case .albumTemplate:
            albumTemplatePreview(previewSize: previewSize)
        case .momentCrop(let template):
            momentCropPreview(previewSize: previewSize, cropSize: cropSize, template: template)
        }
    }

    private func albumTemplatePreview(previewSize: CGSize) -> some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                Color.black

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()

                if showsOutline, let outlineImage {
                    OutlineMaskImageView(image: outlineImage, opacity: 0.96, expansion: 1.2)
                        .transition(.opacity)
                }
            }
            .frame(width: previewSize.width, height: previewSize.height)

            if isExtractingTemplate {
                ProgressView()
                    .tint(.white)
                    .padding(AppTheme.Spacing.s4)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: previewSize.height)
    }

    private func momentCropPreview(
        previewSize: CGSize,
        cropSize: CGSize,
        template: ExtractPhotoTemplate
    ) -> some View {
        ZStack {
            transformedPreviewImage(previewSize: previewSize, cropSize: cropSize, opacity: 0.24)

            ZStack {
                transformedPreviewImage(previewSize: previewSize, cropSize: cropSize)

                if showsOutline, let outlineImage = template.outlineImage {
                    OutlineMaskImageView(image: outlineImage, opacity: 0.94, expansion: 1.2)
                        .frame(width: cropSize.width, height: cropSize.height)
                        .allowsHitTesting(false)
                }

                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous)
                    .stroke(Color.white.opacity(0.92), lineWidth: 2)
            }
            .frame(width: cropSize.width, height: cropSize.height)
            .compositingGroup()
            .clipped(antialiased: false)
            .shadow(color: .black.opacity(0.28), radius: 18, y: 10)
        }
        .frame(width: previewSize.width, height: previewSize.height)
        .contentShape(Rectangle())
        .gesture(dragGesture(previewSize: previewSize, cropSize: cropSize))
        .simultaneousGesture(magnificationGesture(previewSize: previewSize, cropSize: cropSize))
    }

    private func transformedPreviewImage(
        previewSize: CGSize,
        cropSize: CGSize,
        opacity: Double = 1
    ) -> some View {
        Image(uiImage: image)
            .resizable()
            .frame(width: previewSize.width, height: previewSize.height)
            .scaleEffect(baseCoverScale(for: previewSize, cropSize: cropSize) * zoomScale)
            .rotationEffect(rotationAngle)
            .offset(clampedOffset(for: previewSize, cropSize: cropSize))
            .opacity(opacity)
            .frame(width: previewSize.width, height: previewSize.height)
    }

    private func bottomToolbar(previewSize: CGSize, cropSize: CGSize, bottomInset: CGFloat) -> some View {
        HStack(spacing: 0) {
            Button {
                rotateClockwise(previewSize: previewSize, cropSize: cropSize)
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

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 92)
        .padding(.horizontal, AppTheme.Spacing.s2)
        .padding(.top, AppTheme.Spacing.s2)
        .padding(.bottom, max(bottomInset, AppTheme.Spacing.s4))
        .background(Color.black.opacity(0.96))
    }

    private func previewSize(for availableWidth: CGFloat) -> CGSize {
        let safeWidth = max(availableWidth, 1)
        let aspectRatio = max(image.size.width, 1) / max(image.size.height, 1)
        return CGSize(width: safeWidth, height: safeWidth / aspectRatio)
    }

    private func cropSize(in previewSize: CGSize) -> CGSize {
        guard case .momentCrop(let template) = mode else {
            return previewSize
        }

        let horizontalInset = AppTheme.Spacing.s4
        let verticalInset = AppTheme.Spacing.s4
        let maxWidth = max(180, previewSize.width - horizontalInset * 2)
        let maxHeight = max(180, previewSize.height - verticalInset * 2)
        let aspectRatio = max(template.aspectRatio, 0.01)

        var width = maxWidth
        var height = width / aspectRatio

        if height > maxHeight {
            height = maxHeight
            width = height * aspectRatio
        }

        return CGSize(width: width, height: height)
    }

    private func dragGesture(previewSize: CGSize, cropSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let proposedOffset = CGSize(
                    width: committedOffset.width + value.translation.width,
                    height: committedOffset.height + value.translation.height
                )
                offset = clampedOffset(for: previewSize, cropSize: cropSize, proposed: proposedOffset)
            }
            .onEnded { _ in
                committedOffset = offset
            }
    }

    private func magnificationGesture(previewSize: CGSize, cropSize: CGSize) -> some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let proposedScale = max(1, committedZoomScale * value.magnification)
                zoomScale = proposedScale
                offset = clampedOffset(
                    for: previewSize,
                    cropSize: cropSize,
                    proposed: offset,
                    zoom: proposedScale
                )
            }
            .onEnded { _ in
                committedZoomScale = zoomScale
                committedOffset = offset
            }
    }

    private func rotateClockwise(previewSize: CGSize, cropSize: CGSize) {
        quarterTurns = (quarterTurns + 1) % 4
        offset = clampedOffset(for: previewSize, cropSize: cropSize)
        committedOffset = offset
    }

    private func baseCoverScale(for previewSize: CGSize, cropSize: CGSize) -> CGFloat {
        let rotatedPreviewSize = rotatedSize(for: previewSize)
        return max(cropSize.width / rotatedPreviewSize.width, cropSize.height / rotatedPreviewSize.height)
    }

    private func rotatedSize(for size: CGSize) -> CGSize {
        if quarterTurns.isMultiple(of: 2) {
            return size
        }

        return CGSize(width: size.height, height: size.width)
    }

    private func clampedOffset(
        for previewSize: CGSize,
        cropSize: CGSize,
        proposed: CGSize? = nil,
        zoom: CGFloat? = nil
    ) -> CGSize {
        let proposedOffset = proposed ?? offset
        let currentZoom = zoom ?? zoomScale
        let rotatedPreviewSize = rotatedSize(for: previewSize)
        let renderedWidth = rotatedPreviewSize.width * baseCoverScale(for: previewSize, cropSize: cropSize) * currentZoom
        let renderedHeight = rotatedPreviewSize.height * baseCoverScale(for: previewSize, cropSize: cropSize) * currentZoom

        let horizontalLimit = max(0, (renderedWidth - cropSize.width) / 2)
        let verticalLimit = max(0, (renderedHeight - cropSize.height) / 2)

        return CGSize(
            width: min(max(proposedOffset.width, -horizontalLimit), horizontalLimit),
            height: min(max(proposedOffset.height, -verticalLimit), verticalLimit)
        )
    }

    private func confirm(previewSize: CGSize, cropSize: CGSize) {
        switch mode {
        case .albumTemplate:
            let draft = extractedTemplateDraft ?? AlbumTemplateOutlineDraft(photoSize: image.size, outlineImage: nil)
            onConfirm(.albumTemplate(ExtractPhotoAlbumResult(image: image, templateDraft: draft)))
        case .momentCrop(let template):
            onConfirm(.croppedMomentImage(exportCroppedImage(previewSize: previewSize, cropSize: cropSize, template: template)))
        }

        dismiss()
    }

    private func exportCroppedImage(previewSize: CGSize, cropSize: CGSize, template: ExtractPhotoTemplate) -> UIImage {
        let outputSize = template.exportSize()
        let translation = clampedOffset(for: previewSize, cropSize: cropSize)
        let rotatedSourceSize = quarterTurns.isMultiple(of: 2)
            ? image.size
            : CGSize(width: image.size.height, height: image.size.width)
        let baseScale = max(outputSize.width / rotatedSourceSize.width, outputSize.height / rotatedSourceSize.height)
        let outputTranslation = CGSize(
            width: (translation.width / cropSize.width) * outputSize.width,
            height: (translation.height / cropSize.height) * outputSize.height
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

            image.draw(
                in: CGRect(
                    x: -image.size.width / 2,
                    y: -image.size.height / 2,
                    width: image.size.width,
                    height: image.size.height
                )
            )
        }
    }

    private func prepareAlbumTemplateIfNeeded() {
        guard case .albumTemplate = mode,
              extractedTemplateDraft == nil,
              !isExtractingTemplate else {
            return
        }

        isExtractingTemplate = true

        let sourceImage = image
        Task {
            let draft = await PersonOutlineExtractionService.extract(from: sourceImage)

            await MainActor.run {
                guard isExtractingTemplate else {
                    return
                }

                extractedTemplateDraft = draft
                isExtractingTemplate = false
            }
        }
    }

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

#Preview("Album Template") {
    let image = UIGraphicsImageRenderer(size: CGSize(width: 960, height: 1_280)).image { ctx in
        UIColor.systemIndigo.setFill()
        ctx.fill(ctx.format.bounds)
    }

    return ExtractPhotoView(image: image, mode: .albumTemplate) { _ in }
}

#Preview("Moment Crop") {
    let image = UIGraphicsImageRenderer(size: CGSize(width: 1_280, height: 960)).image { ctx in
        UIColor.systemTeal.setFill()
        ctx.fill(ctx.format.bounds)
    }
    let outline = UIGraphicsImageRenderer(size: CGSize(width: 1_280, height: 960)).image { ctx in
        UIColor.clear.setFill()
        ctx.fill(ctx.format.bounds)
        UIColor.white.setStroke()
        ctx.cgContext.setLineWidth(12)
        ctx.cgContext.strokeEllipse(in: CGRect(x: 320, y: 140, width: 640, height: 760))
    }

    return ExtractPhotoView(
        image: image,
        mode: .momentCrop(template: ExtractPhotoTemplate(outlineImage: outline, photoSize: outline.size))
    ) { _ in }
}
#endif
