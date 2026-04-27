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
    @State private var isCreationPresented = false
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
        ZStack {
            AppPageBackground(style: .dotted)

            Group {
                if viewModel.moments.isEmpty {
                    ContentUnavailableView(
                        "No moments yet",
                        systemImage: "clock.badge.plus",
                        description: Text("Add a moment from the toolbar.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(viewModel.moments.enumerated()), id: \.element.id) { index, moment in
                                timelineRow(for: moment, at: index)
                            }
                        }
                        .padding(.leading, AppTheme.Spacing.s5)
                        .padding(.bottom, AppTheme.Spacing.s10)
                    }
                }
            }
        }
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
                        isCreationPresented = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add moment")
                }
            }
        }
        .fullScreenCover(isPresented: $isCreationPresented) {
            NavigationStack {
                MomentCreationView(mode: .newMoment(album: album)) { _ in }
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
            bottomSpacing: index == viewModel.moments.count - 1 ? 0 : AppTheme.Spacing.s6,
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

private struct TimelinePendingShareInput: Identifiable {
    let id = UUID()
    let moment: Moment
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Album.self, Moment.self, configurations: config)

    let album = Album(name: "Tokyo Trip 2024")
    container.mainContext.insert(album)

    let entries: [(TimeInterval, String)] = [
        (1_713_715_200, "Neon signs everywhere — the city never sleeps."),
        (1_713_628_800, "Golden hour at the famous crossing."),
        (1_713_542_400, "Colourful street fashion and crepe shops.")
    ]
    for (ts, note) in entries {
        container.mainContext.insert(Moment(
            album: album, photo: "", note: note,
            createdAt: Date(timeIntervalSince1970: ts)
        ))
    }

    return NavigationStack {
        MomentsTimelineView(album: album)
    }
    .modelContainer(container)
}
