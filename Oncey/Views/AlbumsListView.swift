import SwiftUI
import SwiftData

struct AlbumsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Album.updatedAt, order: .reverse), SortDescriptor(\Album.createdAt, order: .reverse)]) private var albums: [Album]
    @State private var viewModel = AlbumsViewModel()
    @State private var isCreationPresented = false
    @State private var reminderCreationTarget: ReminderCreationTarget?
    @State private var pendingTimelineAlbumID: UUID?
    @State private var pendingDeleteAlbum: Album?
    @State private var errorTitle = "Couldn't delete album"
    @State private var errorMessage: String?
    @State private var isPresentingError = false

    var body: some View {
        ZStack {
            AppPageBackground(style: .dotted)

            Group {
                if albums.isEmpty {
                    ContentUnavailableView(
                        "No albums yet",
                        systemImage: "photo.on.rectangle.angled",
                        description: Text("Create your first album from the add button.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: AppTheme.Spacing.s6) {
                            if let reminderAlbum,
                               let reminderText = viewModel.reminderBannerText(for: reminderAlbum) {
                                Button {
                                    reminderCreationTarget = ReminderCreationTarget(id: reminderAlbum.id)
                                } label: {
                                    AlbumReminderEntryView(
                                        albumName: reminderAlbum.name,
                                        reminderText: reminderText
                                    )
                                }
                                .buttonStyle(.plain)
                            }

                            ForEach(albums) { album in
                                NavigationLink {
                                    MomentsView(album: album)
                                } label: {
                                    AlbumCardView(
                                        album: album,
                                        coverPhotoPath: viewModel.coverPhotoPath(for: album),
                                        albumCreatedText: viewModel.albumCreatedText(for: album),
                                        momentCountText: viewModel.momentCountText(for: album),
                                        reminderCountdownText: viewModel.reminderCountdownText(for: album),
                                        displayedMomentNodeCount: viewModel.displayedMomentNodeCount(for: album),
                                        showsReminderNode: viewModel.showsReminderNode(for: album)
                                    )
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        pendingDeleteAlbum = album
                                    } label: {
                                        Label("Delete", systemImage: "trash")
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isCreationPresented = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add album")
            }
        }
        .navigationDestination(isPresented: timelineNavigationBinding) {
            if let pendingTimelineAlbum {
                MomentsView(album: pendingTimelineAlbum)
            }
        }
        .fullScreenCover(isPresented: $isCreationPresented) {
            NavigationStack {
                MomentCreationView(mode: .newAlbum) { album in
                    pendingTimelineAlbumID = album.id
                }
            }
        }
        .fullScreenCover(item: $reminderCreationTarget) { target in
            if let album = albums.first(where: { $0.id == target.id }) {
                NavigationStack {
                    MomentCreationView(mode: .newMoment(album: album)) { album in
                        pendingTimelineAlbumID = album.id
                    }
                }
            } else {
                EmptyView()
            }
        }
        .alert("Delete this album?", isPresented: isPresentingDeleteAlert) {
            Button("Delete", role: .destructive) {
                guard let pendingDeleteAlbum else {
                    return
                }

                deleteAlbum(pendingDeleteAlbum)
                self.pendingDeleteAlbum = nil
            }

            Button("Cancel", role: .cancel) {
                pendingDeleteAlbum = nil
            }
        } message: {
            let albumName = pendingDeleteAlbum?.name ?? "this album"
            Text("This will delete \(albumName) and all associated moments.")
        }
        .alert(errorTitle, isPresented: $isPresentingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
    }

    private var reminderAlbum: Album? {
        viewModel.nextReminderAlbum(in: albums)
    }

    private var pendingTimelineAlbum: Album? {
        guard let pendingTimelineAlbumID else {
            return nil
        }

        return albums.first { $0.id == pendingTimelineAlbumID }
    }

    private var timelineNavigationBinding: Binding<Bool> {
        Binding(
            get: { pendingTimelineAlbumID != nil && pendingTimelineAlbum != nil },
            set: { isPresented in
                if !isPresented {
                    pendingTimelineAlbumID = nil
                }
            }
        )
    }

    private var isPresentingDeleteAlert: Binding<Bool> {
        Binding(
            get: { pendingDeleteAlbum != nil },
            set: { isPresented in
                if !isPresented {
                    pendingDeleteAlbum = nil
                }
            }
        )
    }

    private func deleteAlbum(_ album: Album) {
        do {
            try AlbumDeletionService.delete(album, in: modelContext)
        } catch {
            errorTitle = "Couldn't delete album"
            errorMessage = error.localizedDescription
            isPresentingError = true
        }
    }
}

private struct ReminderCreationTarget: Identifiable {
    let id: UUID
}

private struct AlbumReminderEntryView: View {
    let albumName: String
    let reminderText: String

    var body: some View {
        HStack(spacing: AppTheme.Spacing.s5) {
            Circle()
                .fill(.accent)
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.s2) {
                Text(albumName)
                    .font(.title3.weight(.medium))
                    .lineLimit(1)

                Text(reminderText)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .frame(width: 16, height: 16)
                .foregroundStyle(AppTheme.Colors.accentSoft)
        }
        .padding(AppTheme.Spacing.s5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous)
                .fill(AppTheme.Colors.surface)
                .shadow(color: AppTheme.Colors.shadow, radius: AppTheme.Shadow.softRadius, y: AppTheme.Shadow.softYOffset)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Album.self, Moment.self, configurations: config)
    let now = Date.now

    let album1 = Album(
        name: "Tokyo Trip 2024",
        createdAt: now.addingTimeInterval(-86_400 * 30),
        updatedAt: now.addingTimeInterval(-86_400 * 2)
    )
    container.mainContext.insert(album1)
    container.mainContext.insert(Moment(
        album: album1,
        photo: "",
        note: "Golden hour at the famous crossing.",
        createdAt: now.addingTimeInterval(-86_400 * 10)
    ))
    container.mainContext.insert(Moment(
        album: album1,
        photo: "",
        note: "Neon signs and night-market energy.",
        createdAt: now.addingTimeInterval(-86_400 * 2)
    ))
    album1.remindValue = 1
    album1.remindUnit = .week
    album1.remindAt = now.addingTimeInterval(86_400 * 4)

    let album2 = Album(
        name: "Weekend Escape",
        createdAt: now.addingTimeInterval(-86_400 * 20),
        updatedAt: now.addingTimeInterval(-86_400)
    )
    container.mainContext.insert(album2)
    container.mainContext.insert(Moment(
        album: album2,
        photo: "",
        note: "Misty morning hike along the shore.",
        createdAt: now.addingTimeInterval(-86_400)
    ))

    let album3 = Album(
        name: "No Record Yet",
        createdAt: now.addingTimeInterval(-86_400 * 8),
        updatedAt: now.addingTimeInterval(-86_400 * 8)
    )
    container.mainContext.insert(album3)

    return NavigationStack {
        AlbumsListView()
    }
    .modelContainer(container)
}
