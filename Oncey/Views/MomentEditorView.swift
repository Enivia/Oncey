#if canImport(UIKit)
import PhotosUI
import SwiftData
import SwiftUI
import UIKit

enum MomentEditorMode {
    case newAlbum(initialImage: UIImage)
    case newMoment(album: Album, initialImage: UIImage)
    case editMoment(moment: Moment)

    var showsAlbumNameField: Bool {
        if case .newAlbum = self {
            return true
        }

        return false
    }

    var navigationTitle: String {
        switch self {
        case .newAlbum:
            return ""
        case .newMoment:
            return "New Moment"
        case .editMoment:
            return "Edit Moment"
        }
    }

    var autoRefreshLocation: Bool {
        switch self {
        case .newAlbum, .newMoment:
            return true
        case .editMoment:
            return false
        }
    }
}

enum MomentEditorCompletion {
    case createdAlbum(UUID)
    case finished
}

struct MomentEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @FocusState private var isAlbumNameFocused: Bool

    let mode: MomentEditorMode
    let onComplete: (MomentEditorCompletion) -> Void

    @State private var albumName: String
    @State private var note: String
    @State private var draftImage: UIImage?
    @State private var locationService: CurrentLocationService
    @State private var hasAutoRequestedLocation = false
    @State private var hasImageChanges: Bool
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isPhotoPickerPresented = false
    @State private var pendingCropInput: PendingCropInput?
    @State private var pendingReplacementImage: UIImage?
    @State private var errorMessage: String?
    @State private var isPresentingError = false
    @State private var isSaving = false

    init(mode: MomentEditorMode, onComplete: @escaping (MomentEditorCompletion) -> Void = { _ in }) {
        self.mode = mode
        self.onComplete = onComplete

        switch mode {
        case .newAlbum(let image):
            _albumName = State(initialValue: "")
            _note = State(initialValue: "")
            _draftImage = State(initialValue: image)
            _locationService = State(initialValue: CurrentLocationService())
            _hasImageChanges = State(initialValue: true)
        case .newMoment(_, let image):
            _albumName = State(initialValue: "")
            _note = State(initialValue: "")
            _draftImage = State(initialValue: image)
            _locationService = State(initialValue: CurrentLocationService())
            _hasImageChanges = State(initialValue: true)
        case .editMoment(let moment):
            _albumName = State(initialValue: "")
            _note = State(initialValue: moment.note)
            _draftImage = State(initialValue: ImageResourceService.platformImage(from: moment.photo))
            _locationService = State(initialValue: CurrentLocationService(initialLocation: moment.location))
            _hasImageChanges = State(initialValue: false)
        }
    }

    var body: some View {
        ZStack {
            AppPageBackground()

            ScrollView {
                VStack(spacing: AppTheme.Spacing.s6) {
                    photoSection
                    locationSection
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

            if mode.showsAlbumNameField {
                ToolbarItem(placement: .principal) {
                    TextField("Album name", text: $albumName)
                        .textInputAutocapitalization(.words)
                        .multilineTextAlignment(.center)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                        .focused($isAlbumNameFocused)
                        .frame(maxWidth: 220)
                        .submitLabel(.done)
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
        .photosPicker(
            isPresented: $isPhotoPickerPresented,
            selection: $selectedPhotoItem,
            matching: .images,
            preferredItemEncoding: .current
        )
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else {
                return
            }

            Task {
                await loadReplacementImage(from: newItem)
            }
        }
        .fullScreenCover(item: $pendingCropInput, onDismiss: applyPendingReplacementIfNeeded) { input in
            PhotoCropView(image: input.image) { croppedImage in
                pendingReplacementImage = croppedImage
            }
        }
        .task {
            guard mode.autoRefreshLocation, !hasAutoRequestedLocation else {
                return
            }

            hasAutoRequestedLocation = true
            locationService.refresh()
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
                isPhotoPickerPresented = true
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

    private var locationSection: some View {
        HStack() {
            Label {
                Text(locationService.displayText)
                    .font(.body.weight(.medium))
            } icon: {
                Image(systemName: locationService.persistedValue.isEmpty ? "location" : "location.fill")
                    .foregroundStyle(AppTheme.Colors.accent)
            }

            Spacer(minLength: AppTheme.Spacing.s2)

            Button {
                locationService.refresh()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16))
            }
            .frame(width: 36, height: 36)
            .background(AppTheme.Colors.accentSoft.opacity(0.8))
            .clipShape(Circle())
            .accessibilityLabel("Refresh location")
        }
        .padding(.horizontal, AppTheme.Spacing.s4)
        .padding(.vertical, AppTheme.Spacing.s2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous)
                .stroke(AppTheme.Colors.border, lineWidth: 1)
        }
        
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

    private func loadReplacementImage(from item: PhotosPickerItem) async {
        do {
            let image = try await PhotosPickerImageLoader.loadImage(from: item)
            pendingCropInput = PendingCropInput(image: image)
        } catch {
            present(error.localizedDescription)
        }

        selectedPhotoItem = nil
    }

    private func applyPendingReplacementIfNeeded() {
        guard let pendingReplacementImage else {
            return
        }

        draftImage = pendingReplacementImage
        hasImageChanges = true
        self.pendingReplacementImage = nil
    }

    private func save() {
        guard !isSaving else {
            return
        }

        if mode.showsAlbumNameField {
            let trimmedAlbumName = albumName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedAlbumName.isEmpty else {
                isAlbumNameFocused = true
                return
            }
        }

        guard let draftImage else {
            present("A photo is required before saving.")
            return
        }

        isSaving = true

        do {
            let now = Date.now

            switch mode {
            case .newAlbum:
                let photoPath = try AppImageStore.store(draftImage)
                let trimmedAlbumName = albumName.trimmingCharacters(in: .whitespacesAndNewlines)
                let album = Album(name: trimmedAlbumName, createdAt: now, updatedAt: now)
                let moment = Moment(
                    album: album,
                    photo: photoPath,
                    location: locationService.persistedValue,
                    note: note,
                    createdAt: now,
                    updatedAt: now
                )

                modelContext.insert(album)
                modelContext.insert(moment)
                try modelContext.save()
                onComplete(.createdAlbum(album.id))
                dismiss()
            case .newMoment(let album, _):
                let photoPath = try AppImageStore.store(draftImage)
                let moment = Moment(
                    album: album,
                    photo: photoPath,
                    location: locationService.persistedValue,
                    note: note,
                    createdAt: now,
                    updatedAt: now
                )

                modelContext.insert(moment)
                try modelContext.save()
                onComplete(.finished)
                dismiss()
            case .editMoment(let moment):
                if hasImageChanges {
                    moment.photo = try AppImageStore.replaceImage(at: moment.photo, with: draftImage)
                }

                moment.location = locationService.persistedValue
                moment.note = note
                moment.updatedAt = now

                try modelContext.save()
                onComplete(.finished)
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

private struct PendingCropInput: Identifiable {
    let id = UUID()
    let image: UIImage
}

#Preview("Edit Moment") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Album.self, Moment.self, configurations: config)

    let album = Album(name: "Tokyo Trip 2024")
    container.mainContext.insert(album)
    let moment = Moment(
        album: album,
        photo: "",
        location: "Shibuya, Tokyo",
        note: "Golden hour at the famous crossing — the city alive with evening rush.",
        createdAt: Date(timeIntervalSince1970: 1_713_628_800)
    )
    container.mainContext.insert(moment)

    return NavigationStack {
        MomentEditorView(mode: .editMoment(moment: moment))
    }
    .modelContainer(container)
}

#Preview("New Album") {
    let image = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 500)).image { ctx in
        UIColor.systemIndigo.withAlphaComponent(0.55).setFill()
        ctx.fill(ctx.format.bounds)
    }

    NavigationStack {
        MomentEditorView(mode: .newAlbum(initialImage: image))
    }
    .modelContainer(for: [Album.self, Moment.self], inMemory: true)
}
#endif
