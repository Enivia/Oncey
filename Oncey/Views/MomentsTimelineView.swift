import PhotosUI
import SwiftUI
#if canImport(SwiftData)
import SwiftData
#endif
#if canImport(UIKit)
import UIKit
#endif

struct MomentsTimelineView: View {
    @Environment(\.modelContext) private var modelContext

    let album: Album
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isPhotoPickerPresented = false
    @State private var pendingCropInput: TimelinePendingCropInput?
    @State private var pendingCroppedImage: UIImage?
    @State private var pendingEditorInput: TimelinePendingEditorInput?
    @State private var pendingShareInput: TimelinePendingShareInput?
    @State private var isSelectionMode = false
    @State private var selectedMomentIDs: Set<UUID> = []
    @State private var pendingSingleDeleteMoment: Moment?
    @State private var isPresentingBulkDeleteConfirmation = false
    @State private var errorTitle = "Couldn't load photo"
    @State private var errorMessage: String?
    @State private var isPresentingError = false

    private var viewModel: MomentsTimelineViewModel {
        MomentsTimelineViewModel(album: album)
    }

    private var selectedCountTitle: String {
        "\(selectedMomentIDs.count) selected"
    }

    private var selectedMoments: [Moment] {
        viewModel.moments.filter { selectedMomentIDs.contains($0.id) }
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
                            timelineRow(for: moment, at: index)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 36)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(isSelectionMode ? selectedCountTitle : viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if isSelectionMode {
                    Button("Close", systemImage: "xmark") {
                        exitSelectionMode()
                    }
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                if isSelectionMode {
                    Button(role: .destructive) {
                        isPresentingBulkDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .disabled(selectedMomentIDs.isEmpty)
                    .accessibilityLabel("Delete selected moments")
                } else {
                    Button {
                        isPhotoPickerPresented = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add moment")
                }
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
        .fullScreenCover(item: $pendingShareInput) { input in
            NavigationStack {
                MomentShareView(moment: input.moment)
            }
        }
        .alert("Delete this moment?", isPresented: isPresentingSingleDeleteAlert) {
            Button("Delete", role: .destructive) {
                guard let pendingSingleDeleteMoment else {
                    return
                }

                deleteMoments([pendingSingleDeleteMoment])
                self.pendingSingleDeleteMoment = nil
            }

            Button("Cancel", role: .cancel) {
                pendingSingleDeleteMoment = nil
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .alert("Delete selected moments?", isPresented: $isPresentingBulkDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteMoments(selectedMoments)
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
        .alert(errorTitle, isPresented: $isPresentingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
    }

    @ViewBuilder
    private func timelineRow(for moment: Moment, at index: Int) -> some View {
        let row = MomentTimelineRowView(
            moment: moment,
            timestampText: viewModel.timestampText(for: moment),
            isFirst: index == 0,
            isLast: index == viewModel.moments.count - 1,
            bottomSpacing: index == viewModel.moments.count - 1 ? 0 : 30,
            isSelectionMode: isSelectionMode,
            isSelected: selectedMomentIDs.contains(moment.id),
            onMultiSelect: {
                enterSelectionMode(selecting: moment)
            },
            onShare: {
                pendingShareInput = TimelinePendingShareInput(moment: moment)
            },
            onDelete: {
                pendingSingleDeleteMoment = moment
            }
        )

        if isSelectionMode {
            Button {
                toggleSelection(for: moment)
            } label: {
                row
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink {
                MomentEditorView(mode: .editMoment(moment: moment))
            } label: {
                row
            }
            .buttonStyle(.plain)
        }
    }

    private func loadSelectedImage(from item: PhotosPickerItem) async {
        do {
            let image = try await PhotosPickerImageLoader.loadImage(from: item)
            pendingCropInput = TimelinePendingCropInput(image: image)
        } catch {
            errorTitle = "Couldn't load photo"
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

    private var isPresentingSingleDeleteAlert: Binding<Bool> {
        Binding(
            get: { pendingSingleDeleteMoment != nil },
            set: { isPresented in
                if !isPresented {
                    pendingSingleDeleteMoment = nil
                }
            }
        )
    }

    private func enterSelectionMode(selecting moment: Moment) {
        isSelectionMode = true
        selectedMomentIDs = [moment.id]
    }

    private func exitSelectionMode() {
        isSelectionMode = false
        selectedMomentIDs.removeAll()
    }

    private func toggleSelection(for moment: Moment) {
        if selectedMomentIDs.contains(moment.id) {
            selectedMomentIDs.remove(moment.id)
        } else {
            selectedMomentIDs.insert(moment.id)
        }
    }

    private func deleteMoments(_ moments: [Moment]) {
        guard !moments.isEmpty else {
            return
        }

        do {
            try MomentDeletionService.delete(moments, in: modelContext)

            selectedMomentIDs.subtract(moments.map(\.id))
            if isSelectionMode, selectedMomentIDs.isEmpty {
                exitSelectionMode()
            }
        } catch {
            errorTitle = "Couldn't delete moment"
            errorMessage = error.localizedDescription
            isPresentingError = true
        }
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

private struct TimelinePendingShareInput: Identifiable {
    let id = UUID()
    let moment: Moment
}

#Preview {
    let album = Album(name: "Timeline Preview")
    let moment = Moment(album: album, photo: "", location: "Berlin, Germany")

    MomentTimelineRowView(
        moment: moment,
        timestampText: "Apr 18, 2026 at 7:05 PM",
        isFirst: true,
        isLast: false,
        bottomSpacing: 30,
        isSelectionMode: false,
        isSelected: false
    )
        .padding()
}
