import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftData)
import SwiftData
#endif

struct AlbumMomentsView: View {
    @Environment(\.modelContext) private var modelContext

    let album: Album
    private let preferredCurrentMomentID: UUID?
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

    init(album: Album, preferredCurrentMomentID: UUID? = nil) {
        self.album = album
        self.preferredCurrentMomentID = preferredCurrentMomentID
    }

    var body: some View {
        let moments = viewModel.moments

        ZStack {
            AppPageBackground()

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
                        let metrics = MomentTimelinePageMetrics(
                            containerSize: proxy.size,
                            heightReference: screenHeight(for: proxy.size)
                        )

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

            if !moments.isEmpty {
                bottomToolbar(for: moments)
            }
        }
        .fullScreenCover(isPresented: $isCreationPresented) {
            NavigationStack {
                CreationView(mode: .newMoment(album: album)) { album in
                    focusMostRecentMoment(in: album)
                }
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
            isCurrent: isCurrent(moment)
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
        currentMomentID = AlbumMomentsViewModel.resolvedCurrentMomentID(
            in: moments,
            currentMomentID: currentMomentID,
            preferredCurrentMomentID: preferredCurrentMomentID
        )
    }

    private func currentMoment(in moments: [Moment]) -> Moment? {
        if let currentMomentID,
           let moment = moments.first(where: { $0.id == currentMomentID }) {
            return moment
        }

        return moments.first
    }

    private func currentYear(in moments: [Moment]) -> Int? {
        viewModel.year(for: currentMoment(in: moments)?.id)
    }

    private func selectYear(_ year: Int, in moments: [Moment]) {
        guard currentYear(in: moments) != year,
              let targetMomentID = viewModel.latestMomentID(inYear: year) else {
            return
        }

        currentMomentID = targetMomentID
    }

    private func editNote(for moment: Moment) {
        pendingNoteEditorInput = TimelinePendingNoteEditorInput(moment: moment)
    }

    private func share(_ moment: Moment) {
        pendingShareInput = TimelinePendingShareInput(moment: moment)
    }

    private func requestDelete(_ moment: Moment) {
        pendingSingleDeleteMoment = moment
    }

    @ToolbarContentBuilder
    private func bottomToolbar(for moments: [Moment]) -> some ToolbarContent {
        let currentMoment = currentMoment(in: moments)
        let currentYear = currentYear(in: moments)

        ToolbarItem(placement: .bottomBar) {
            Menu {
                ForEach(viewModel.availableYears, id: \.self) { year in
                    Button {
                        selectYear(year, in: moments)
                    } label: {
                        if year == currentYear {
                            Label(String(year), systemImage: "checkmark")
                        } else {
                            Text(String(year))
                        }
                    }
                }
            } label: {
                HStack(spacing: AppTheme.Spacing.s2) {
                    Image(systemName: "calendar")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.Colors.accent)

                    Text(currentYear.map(String.init) ?? "--")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.Colors.accent)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }
            .menuOrder(.fixed)
            .accessibilityLabel("Select year")
        }

        ToolbarSpacer(.flexible, placement: .bottomBar)

        if moments.count > 1 {
            ToolbarItem(placement: .bottomBar) {
                NavigationLink {
                    MomentComparisonView(
                        album: album,
                        currentMomentID: resolvedComparisonCurrentMomentID(in: moments)
                    )
                } label: {
                    Image(systemName: "square.and.line.vertical.and.square.filled")
                }
                .accessibilityLabel("Compare")
            }
        }
        
        ToolbarSpacer(.fixed, placement: .bottomBar)

        ToolbarItem(placement: .bottomBar) {
            Menu {
                Button {
                    guard let currentMoment else {
                        return
                    }

                    editNote(for: currentMoment)
                } label: {
                    Label("Note", systemImage: "long.text.page.and.pencil")
                }

                Button {
                    guard let currentMoment else {
                        return
                    }

                    share(currentMoment)
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }

                Button(role: .destructive) {
                    guard let currentMoment else {
                        return
                    }

                    requestDelete(currentMoment)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
            }
            .menuOrder(.fixed)
            .disabled(currentMoment == nil)
            .accessibilityLabel("More actions")
        }
    }

    private func screenHeight(for containerSize: CGSize) -> CGFloat {
#if canImport(UIKit)
        max(containerSize.height, UIScreen.main.bounds.height)
#else
        containerSize.height
#endif
    }

    private func hasNote(_ moment: Moment?) -> Bool {
        guard let moment else {
            return false
        }

        return !moment.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func focusMostRecentMoment(in album: Album) {
        currentMomentID = AlbumMomentsViewModel(album: album).moments.first?.id
    }

    private func resolvedComparisonCurrentMomentID(in moments: [Moment]) -> UUID? {
        guard let currentMomentID,
              moments.contains(where: { $0.id == currentMomentID }) else {
            return moments.first?.id
        }

        return currentMomentID
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
