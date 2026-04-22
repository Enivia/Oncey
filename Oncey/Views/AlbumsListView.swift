import PhotosUI
import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

struct AlbumsListView: View {
    @Query(sort: [SortDescriptor(\Album.updatedAt, order: .reverse), SortDescriptor(\Album.createdAt, order: .reverse)]) private var albums: [Album]
    @State private var viewModel = AlbumsViewModel()
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isPhotoPickerPresented = false
    @State private var pendingCropInput: AlbumsListPendingCropInput?
    @State private var pendingCroppedImage: UIImage?
    @State private var pendingEditorInput: AlbumsListPendingEditorInput?
    @State private var errorMessage: String?
    @State private var isPresentingError = false

    var body: some View {
        Group {
            if albums.isEmpty {
                ContentUnavailableView(
                    "No albums yet",
                    systemImage: "photo.on.rectangle.angled",
                    description: Text("Create your first album from the add button.")
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(albums) { album in
                            NavigationLink {
                                MomentsTimelineView(album: album)
                            } label: {
                                AlbumCardView(
                                    album: album,
                                    coverPhotoPath: viewModel.coverPhotoPath(for: album),
                                    momentCountText: viewModel.momentCountText(for: album),
                                    layerCount: viewModel.layerCount(for: album)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 20)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isPhotoPickerPresented = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add album")
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
                await loadSelectedImage(from: newItem)
            }
        }
        .fullScreenCover(item: $pendingCropInput, onDismiss: presentEditorIfNeeded) { input in
            PhotoCropView(image: input.image) { croppedImage in
                pendingCroppedImage = croppedImage
            }
        }
        .fullScreenCover(item: $pendingEditorInput) { input in
            NavigationStack {
                MomentEditorView(mode: .newAlbum(initialImage: input.image))
            }
        }
        .alert("Couldn't load photo", isPresented: $isPresentingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
    }

    private func loadSelectedImage(from item: PhotosPickerItem) async {
        do {
            let image = try await PhotosPickerImageLoader.loadImage(from: item)
            pendingCropInput = AlbumsListPendingCropInput(image: image)
        } catch {
            errorMessage = error.localizedDescription
            isPresentingError = true
        }

        selectedPhotoItem = nil
    }

    private func presentEditorIfNeeded() {
        guard let pendingCroppedImage else {
            return
        }

        pendingEditorInput = AlbumsListPendingEditorInput(image: pendingCroppedImage)
        self.pendingCroppedImage = nil
    }
}

private struct AlbumsListPendingCropInput: Identifiable {
    let id = UUID()
    let image: UIImage
}

private struct AlbumsListPendingEditorInput: Identifiable {
    let id = UUID()
    let image: UIImage
}

#Preview {
    AlbumsListView()
        .modelContainer(for: [Album.self, Moment.self], inMemory: true)
}