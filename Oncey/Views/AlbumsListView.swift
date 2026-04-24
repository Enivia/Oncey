import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

struct AlbumsListView: View {
    @Query(sort: [SortDescriptor(\Album.updatedAt, order: .reverse), SortDescriptor(\Album.createdAt, order: .reverse)]) private var albums: [Album]
    @State private var viewModel = AlbumsViewModel()
    @State private var isCreationPresented = false
    @State private var pendingTimelineAlbumID: UUID?
    @State private var errorMessage: String?
    @State private var isPresentingError = false

    var body: some View {
        ZStack {
            AppPageBackground(style: .dotted)

            GeometryReader { proxy in
                let albumCardWidth = proxy.size.width * AppTheme.Layout.albumCardWidthRatio

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
                            LazyVStack(spacing: AppTheme.Spacing.s3) {
                                ForEach(albums) { album in
                                    HStack(spacing: 0) {
                                        Spacer(minLength: 0)

                                        NavigationLink {
                                            MomentsTimelineView(album: album)
                                        } label: {
                                            AlbumCardView(
                                                album: album,
                                                coverPhotoPath: viewModel.coverPhotoPath(for: album),
                                                momentCountText: viewModel.momentCountText(for: album),
                                                layerCount: viewModel.layerCount(for: album)
                                            )
                                            .frame(width: albumCardWidth)
                                        }
                                        .buttonStyle(.plain)

                                        Spacer(minLength: 0)
                                    }
                                }
                            }
                            .padding(.horizontal, AppTheme.Spacing.s4)
                            .padding(.vertical, AppTheme.Spacing.s6)
                        }
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
                MomentsTimelineView(album: pendingTimelineAlbum)
            }
        }
        .fullScreenCover(isPresented: $isCreationPresented) {
            NavigationStack {
                MomentCreationView(mode: .newAlbum) { album in
                    pendingTimelineAlbumID = album.id
                }
            }
        }
        .alert("Couldn't load photo", isPresented: $isPresentingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
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
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Album.self, Moment.self, configurations: config)

    let album1 = Album(name: "Tokyo Trip 2024")
    container.mainContext.insert(album1)
    container.mainContext.insert(Moment(
        album: album1, photo: "", location: "Shibuya, Tokyo",
        note: "Golden hour at the famous crossing.",
        createdAt: Date(timeIntervalSince1970: 1_713_628_800)
    ))
    container.mainContext.insert(Moment(
        album: album1, photo: "", location: "Shinjuku, Tokyo",
        note: "Neon signs and night-market energy.",
        createdAt: Date(timeIntervalSince1970: 1_713_715_200)
    ))

    let album2 = Album(name: "Weekend Escape")
    container.mainContext.insert(album2)
    container.mainContext.insert(Moment(
        album: album2, photo: "", location: "Lake District, UK",
        note: "Misty morning hike along the shore."
    ))

    return NavigationStack {
        AlbumsListView()
    }
    .modelContainer(container)
}