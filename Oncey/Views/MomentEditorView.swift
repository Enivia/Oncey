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
        ScrollView {
            VStack(spacing: 22) {
                photoSection
                locationSection
                noteSection
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 20)
        }
        .background(Color(.systemGroupedBackground))
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
        editorCard(title: "Photo") {
            ZStack(alignment: .bottomTrailing) {
                photoPreview

                Button("Change") {
                    isPhotoPickerPresented = true
                }
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .padding(16)
            }
        }
    }

    @ViewBuilder
    private var photoPreview: some View {
        Group {
            if let draftImage {
                Image(uiImage: draftImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 220, maxHeight: 340)
                    .background(Color(.secondarySystemGroupedBackground))
            } else if let existingPath = existingPhotoPath {
                LocalPhotoView(path: existingPath)
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 220, maxHeight: 340)
                    .background(Color(.secondarySystemGroupedBackground))
            } else {
                Color(.secondarySystemGroupedBackground)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 220, maxHeight: 340)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.system(size: 30, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var locationSection: some View {
        editorCard(title: "Location") {
            HStack(spacing: 14) {
                Label {
                    Text(locationService.displayText)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                } icon: {
                    Image(systemName: locationService.isRefreshing ? "location.fill" : "location")
                        .foregroundStyle(Color.accentColor)
                }

                Spacer(minLength: 12)

                Button {
                    locationService.refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.headline.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Refresh location")
            }
        }
    }

    private var noteSection: some View {
        editorCard(title: "Note") {
            TextEditor(text: $note)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 160)
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private var existingPhotoPath: String? {
        if case .editMoment(let moment) = mode {
            return moment.photo
        }

        return nil
    }

    private func editorCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.secondary)

            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.04), radius: 20, y: 10)
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

private struct PendingCropInput: Identifiable {
    let id = UUID()
    let image: UIImage
}
#endif