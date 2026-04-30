import SwiftUI
#if canImport(SwiftData)
import SwiftData
#endif

struct AlbumMomentsView: View {
    @Environment(\.modelContext) private var modelContext

    let album: Album
    @State private var isCreationPresented = false
    @State private var pendingNoteEditorInput: TimelinePendingNoteEditorInput?
    @State private var pendingShareInput: TimelinePendingShareInput?
    @State private var currentMomentID: UUID?
    @State private var pendingSingleDeleteMoment: Moment?
    @State private var errorTitle = "Couldn't load photo"
    @State private var errorMessage: String?
    @State private var isPresentingError = false

    private var viewModel: AlbumMomentsViewModel {
        AlbumMomentsViewModel(album: album)
    }

    var body: some View {
        let moments = viewModel.moments

        ZStack {
            AppPageBackground(style: .dotted)

            Group {
                if moments.isEmpty {
                    ContentUnavailableView(
                        "No moments yet",
                        systemImage: "clock.badge.plus",
                        description: Text("Add a moment from the toolbar.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    GeometryReader { proxy in
                        let metrics = MomentTimelinePageMetrics(containerSize: proxy.size)

                        ScrollView(.vertical) {
                            LazyVStack(spacing: 0) {
                                ForEach(moments, id: \.id) { moment in
                                    momentRow(for: moment, metrics: metrics)
                                        .frame(width: proxy.size.width, height: metrics.pageSize.height)
                                        .id(moment.id)
                                }
                            }
                            .padding(.vertical, metrics.verticalInset)
                            .scrollTargetLayout()
                        }
                        .scrollIndicators(.hidden)
                        .scrollTargetBehavior(.viewAligned(limitBehavior: .alwaysByFew))
                        .scrollPosition(id: $currentMomentID, anchor: .center)
                        .onAppear {
                            syncCurrentMomentID(with: moments)
                        }
                        .onChange(of: moments.map(\.id)) { _, _ in
                            syncCurrentMomentID(with: moments)
                        }
                    }
                }
            }
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .sheet(item: $pendingNoteEditorInput) { input in
            NavigationStack {
                MomentNoteEditorSheet(moment: input.moment)
            }
            .presentationDetents([.medium])
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isCreationPresented = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add moment")
            }
        }
        .fullScreenCover(isPresented: $isCreationPresented) {
            NavigationStack {
                CreationView(mode: .newMoment(album: album)) { _ in }
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
        .alert(errorTitle, isPresented: $isPresentingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
    }

    private func momentRow(for moment: Moment, metrics: MomentTimelinePageMetrics) -> some View {
        AlbumMomentTileView(
            moment: moment,
            timestampText: viewModel.timestampText(for: moment),
            metrics: metrics,
            isCurrent: isCurrent(moment),
            onEditNote: {
                pendingNoteEditorInput = TimelinePendingNoteEditorInput(moment: moment)
            },
            onShare: {
                pendingShareInput = TimelinePendingShareInput(moment: moment)
            },
            onDelete: {
                pendingSingleDeleteMoment = moment
            }
        )
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

    private func isCurrent(_ moment: Moment) -> Bool {
        if let currentMomentID {
            return currentMomentID == moment.id
        }

        return viewModel.moments.first?.id == moment.id
    }

    private func syncCurrentMomentID(with moments: [Moment]) {
        guard let firstMoment = moments.first else {
            currentMomentID = nil
            return
        }

        guard let currentMomentID else {
            self.currentMomentID = firstMoment.id
            return
        }

        if !moments.contains(where: { $0.id == currentMomentID }) {
            self.currentMomentID = firstMoment.id
        }
    }

    private func deleteMoments(_ moments: [Moment]) {
        guard !moments.isEmpty else {
            return
        }

        do {
            try MomentDeletionService.delete(moments, in: modelContext)
            syncCurrentMomentID(with: viewModel.moments)
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

private struct TimelinePendingNoteEditorInput: Hashable, Identifiable {
    let id: UUID
    let moment: Moment

    init(moment: Moment) {
        self.id = moment.id
        self.moment = moment
    }

    static func == (lhs: TimelinePendingNoteEditorInput, rhs: TimelinePendingNoteEditorInput) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
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
        AlbumMomentsView(album: album)
    }
    .modelContainer(container)
}
