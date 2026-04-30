import SwiftUI
import SwiftData

struct MomentsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [
        SortDescriptor(\Moment.createdAt, order: .reverse),
        SortDescriptor(\Moment.updatedAt, order: .reverse)
    ]) private var moments: [Moment]

    @State private var pendingNoteEditorInput: TimelinePendingNoteEditorInput?
    @State private var pendingShareInput: TimelinePendingShareInput?
    @State private var pendingDeleteMoment: Moment?
    @State private var errorMessage: String?
    @State private var isPresentingError = false

    private let viewModel = MomentsViewModel()

    var body: some View {
        let sections = viewModel.sections(from: moments)

        ZStack {
            AppPageBackground(style: .dotted)

            Group {
                if moments.isEmpty {
                    ContentUnavailableView(
                        "No moments yet",
                        systemImage: "clock.badge.questionmark",
                        description: Text("Moments from every album will appear here once you create them.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: AppTheme.Spacing.s7) {
                            ForEach(sections) { section in
                                VStack(alignment: .leading, spacing: AppTheme.Spacing.s4) {
                                    Text(section.title)
                                        .font(.title3.weight(.semibold))
                                        .foregroundStyle(AppTheme.Colors.textPrimary)
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    VStack(spacing: AppTheme.Spacing.s5) {
                                        ForEach(section.moments) { moment in
                                            MomentTileView(
                                                moment: moment,
                                                monthDayText: viewModel.monthDayText(for: moment),
                                                albumNameText: viewModel.albumNameText(for: moment),
                                                onEditNote: {
                                                    pendingNoteEditorInput = TimelinePendingNoteEditorInput(moment: moment)
                                                },
                                                onShare: {
                                                    pendingShareInput = TimelinePendingShareInput(moment: moment)
                                                },
                                                onDelete: {
                                                    pendingDeleteMoment = moment
                                                }
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.s6)
                        .padding(.vertical, AppTheme.Spacing.s6)
                    }
                }
            }
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $pendingNoteEditorInput) { input in
            NavigationStack {
                MomentNoteEditorSheet(moment: input.moment)
            }
            .presentationDetents([.medium])
        }
        .fullScreenCover(item: $pendingShareInput) { input in
            NavigationStack {
                MomentShareView(moment: input.moment)
            }
        }
        .alert("Delete this moment?", isPresented: isPresentingDeleteAlert) {
            Button("Delete", role: .destructive) {
                guard let pendingDeleteMoment else {
                    return
                }

                deleteMoment(pendingDeleteMoment)
                self.pendingDeleteMoment = nil
            }

            Button("Cancel", role: .cancel) {
                pendingDeleteMoment = nil
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .alert("Couldn't delete moment", isPresented: $isPresentingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
    }

    private var isPresentingDeleteAlert: Binding<Bool> {
        Binding(
            get: { pendingDeleteMoment != nil },
            set: { isPresented in
                if !isPresented {
                    pendingDeleteMoment = nil
                }
            }
        )
    }

    private func deleteMoment(_ moment: Moment) {
        do {
            try MomentDeletionService.delete([moment], in: modelContext)
        } catch {
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

    let springAlbum = Album(name: "Spring Walk")
    let tripAlbum = Album(name: "Kyoto Trip")
    container.mainContext.insert(springAlbum)
    container.mainContext.insert(tripAlbum)

    container.mainContext.insert(Moment(
        album: springAlbum,
        photo: "",
        note: "First warm breeze of the year.",
        createdAt: Date(timeIntervalSince1970: 1_746_057_600)
    ))
    container.mainContext.insert(Moment(
        album: tripAlbum,
        photo: "",
        note: "",
        createdAt: Date(timeIntervalSince1970: 1_713_715_200)
    ))
    container.mainContext.insert(Moment(
        album: tripAlbum,
        photo: "",
        note: "Lanterns glowing after sunset.",
        createdAt: Date(timeIntervalSince1970: 1_702_166_400)
    ))

    return NavigationStack {
        MomentsView()
    }
    .modelContainer(container)
}
