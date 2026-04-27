#if canImport(UIKit)
import SwiftData
import SwiftUI
import UIKit

enum MomentEditorMode {
    case editMoment(moment: Moment)

    var navigationTitle: String {
        switch self {
        case .editMoment:
            return "Edit Moment"
        }
    }
}

struct MomentEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let mode: MomentEditorMode
    let onComplete: () -> Void

    @State private var note: String
    @State private var draftImage: UIImage?
    @State private var hasImageChanges: Bool
    @State private var isCameraPresented = false
    @State private var pendingExtractInput: PendingExtractInput?
    @State private var errorMessage: String?
    @State private var isPresentingError = false
    @State private var isSaving = false

    init(mode: MomentEditorMode, onComplete: @escaping () -> Void = {}) {
        self.mode = mode
        self.onComplete = onComplete

        switch mode {
        case .editMoment(let moment):
            _note = State(initialValue: moment.note)
            _draftImage = State(initialValue: ImageResourceService.platformImage(from: moment.photo))
            _hasImageChanges = State(initialValue: false)
        }
    }

    var body: some View {
        ZStack {
            AppPageBackground()

            ScrollView {
                VStack(spacing: AppTheme.Spacing.s6) {
                    photoSection
                    noteSection
                }
                .padding(.horizontal, AppTheme.Spacing.s6)
                .padding(.vertical, AppTheme.Spacing.s6)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .navigationTitle(mode.navigationTitle)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Back", systemImage: "chevron.backward") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    save()
                }
                .fontWeight(.semibold)
                .disabled(isSaving)
            }
        }
        .fullScreenCover(isPresented: $isCameraPresented) {
            CameraView(template: cameraTemplate) { image in
                Task { @MainActor in
                    await Task.yield()
                    pendingExtractInput = PendingExtractInput(image: image, mode: extractMode(for: image))
                }
            }
        }
        .fullScreenCover(item: $pendingExtractInput) { input in
            ExtractPhotoView(image: input.image, mode: input.mode) { output in
                if case .croppedMomentImage(let croppedImage) = output {
                    draftImage = croppedImage
                    hasImageChanges = true
                }
            }
        }
        .alert("Something went wrong", isPresented: $isPresentingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
    }

    private var photoSection: some View {
        ZStack(alignment: .bottomTrailing) {
            photoPreview

            Button {
                isCameraPresented = true
            }
            label: {
                Label("Change", systemImage: "photo")
                    .padding(.horizontal, AppTheme.Spacing.s2)
                    .padding(.vertical, AppTheme.Spacing.s1)
            }
            .buttonStyle(.glass)
            .padding(AppTheme.Spacing.s5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var photoPreview: some View {
        Group {
            if let draftImage {
                photoPreview(image: draftImage, size: draftImage.size)
            } else if let existingPath = existingPhotoPath {
                photoPreview(path: existingPath)
            } else {
                AppTheme.Colors.background
                    .frame(maxWidth: .infinity)
                    .frame(height: 240)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.system(size: 30, weight: .medium))
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var noteSection: some View {
        ZStack(alignment: .topLeading) {
            NoteEditorBackground()

            TextEditor(text: $note)
                .frame(height: 140)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, AppTheme.Spacing.s4)
                .padding(.vertical, AppTheme.Spacing.s2)
                .background(Color.clear)

            if note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("Add a note...")
                    .font(.body)
                    .foregroundStyle(AppTheme.Colors.textSecondary.opacity(0.7))
                    .padding(.horizontal, AppTheme.Spacing.s5)
                    .padding(.vertical, AppTheme.Spacing.s5)
                    .allowsHitTesting(false)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous)
                .stroke(AppTheme.Colors.border, lineWidth: 1)
        }
    }

    private var existingPhotoPath: String? {
        if case .editMoment(let moment) = mode {
            return moment.photo
        }

        return nil
    }

    private func photoPreview(image: UIImage, size: CGSize) -> some View {
        return Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous))
    }

    private func photoPreview(path: String) -> some View {
        return LocalPhotoView(path: path, contentMode: .fit)
            .aspectRatio(imageAspectRatio(for: ImageResourceService.imageSize(from: path)), contentMode: .fit)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous))
    }

    private func imageAspectRatio(for size: CGSize?) -> CGFloat? {
        guard let size, size.width > 0, size.height > 0 else {
            return nil
        }

        return size.width / size.height
    }

    private func save() {
        guard !isSaving else {
            return
        }

        guard let draftImage else {
            present("A photo is required before saving.")
            return
        }

        isSaving = true

        do {
            let now = Date.now

            switch mode {
            case .editMoment(let moment):
                if hasImageChanges {
                    moment.photo = try AppImageStore.replaceImage(at: moment.photo, with: draftImage)
                }

                moment.note = note
                moment.updatedAt = now

                try modelContext.save()
                onComplete()
                dismiss()
            }
        } catch {
            present(error.localizedDescription)
        }

        isSaving = false
    }

    private func present(_ message: String) {
        errorMessage = message
        isPresentingError = true
    }

    private var cameraTemplate: ExtractPhotoTemplate? {
        switch mode {
        case .editMoment(let moment):
            guard let album = moment.album else {
                return nil
            }

            guard album.templatePhotoSize != nil || album.templateOutlinePath != nil else {
                return nil
            }

            return AlbumTemplateResolver.resolve(
                for: album,
                fallbackPhotoSize: album.templatePhotoSize ?? CGSize(width: 3, height: 4)
            )
        }
    }

    private func extractMode(for image: UIImage) -> ExtractPhotoMode {
        switch mode {
        case .editMoment(let moment):
            return .momentCrop(template: AlbumTemplateResolver.resolve(for: moment.album, fallbackPhotoSize: image.size))
        }
    }
}

private struct NoteEditorBackground: View {
    private let lineSpacing: CGFloat = 32
    private let topInset: CGFloat = 36

    var body: some View {
        Canvas(rendersAsynchronously: true) { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(AppTheme.Colors.surface))

            for y in stride(from: topInset, through: size.height, by: lineSpacing) {
                var line = Path()
                line.move(to: CGPoint(x: AppTheme.Spacing.s4, y: y))
                line.addLine(to: CGPoint(x: size.width - AppTheme.Spacing.s4, y: y))
                context.stroke(line, with: .color(AppTheme.Colors.accentSoft.opacity(0.8)), lineWidth: 1)
            }
        }
    }
}

private struct PendingExtractInput: Identifiable {
    let id = UUID()
    let image: UIImage
    let mode: ExtractPhotoMode
}

#Preview("Edit Moment") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Album.self, Moment.self, configurations: config)

    let album = Album(name: "Tokyo Trip 2024")
    container.mainContext.insert(album)
    let moment = Moment(
        album: album,
        photo: "",
        note: "Golden hour at the famous crossing — the city alive with evening rush.",
        createdAt: Date(timeIntervalSince1970: 1_713_628_800)
    )
    container.mainContext.insert(moment)

    return NavigationStack {
        MomentEditorView(mode: .editMoment(moment: moment))
    }
    .modelContainer(container)
}

#endif
