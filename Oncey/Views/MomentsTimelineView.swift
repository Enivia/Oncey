import PhotosUI
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct MomentsTimelineView: View {
    let album: Album
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isPhotoPickerPresented = false
    @State private var pendingCropInput: TimelinePendingCropInput?
    @State private var pendingCroppedImage: UIImage?
    @State private var pendingEditorInput: TimelinePendingEditorInput?
    @State private var errorMessage: String?
    @State private var isPresentingError = false

    private var viewModel: MomentsTimelineViewModel {
        MomentsTimelineViewModel(album: album)
    }

    var body: some View {
        Group {
            if viewModel.moments.isEmpty {
                ContentUnavailableView(
                    "No moments yet",
                    systemImage: "clock.badge.plus",
                    description: Text("Add a moment from the toolbar.")
                )
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(viewModel.moments.enumerated()), id: \.element.id) { index, moment in
                            NavigationLink {
                                MomentEditorView(mode: .editMoment(moment: moment))
                            } label: {
                                MomentTimelineRowView(
                                    moment: moment,
                                    timestampText: viewModel.timestampText(for: moment),
                                    isFirst: index == 0,
                                    isLast: index == viewModel.moments.count - 1,
                                    bottomSpacing: index == viewModel.moments.count - 1 ? 0 : 30
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 36)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isPhotoPickerPresented = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add moment")
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
                MomentEditorView(mode: .newMoment(album: album, initialImage: input.image))
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
            pendingCropInput = TimelinePendingCropInput(image: image)
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

        pendingEditorInput = TimelinePendingEditorInput(image: pendingCroppedImage)
        self.pendingCroppedImage = nil
    }
}

private struct TimelinePendingCropInput: Identifiable {
    let id = UUID()
    let image: UIImage
}

private struct TimelinePendingEditorInput: Identifiable {
    let id = UUID()
    let image: UIImage
}

#Preview {
    let album = Album(name: "Timeline Preview")
    let moment = Moment(album: album, photo: "", location: "Berlin, Germany")

    MomentTimelineRowView(moment: moment, timestampText: "Apr 18, 2026 at 7:05 PM", isFirst: true, isLast: false, bottomSpacing: 30)
        .padding()
}
