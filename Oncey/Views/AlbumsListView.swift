//
//  AlbumsListView.swift
//  Oncey
//

import SwiftUI
import SwiftData

struct AlbumsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Album.updatedAt, order: .reverse), SortDescriptor(\Album.createdAt, order: .reverse)]) private var albums: [Album]
    @State private var viewModel = AlbumsViewModel()

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(albums) { album in
                    NavigationLink {
                        MomentsTimelineView(album: album)
                    } label: {
                        AlbumCardView(
                            album: album,
                            coverPhotoPath: viewModel.coverPhotoPath(for: album),
                            momentCountText: viewModel.momentCountText(for: album)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Albums")
        .task {
            viewModel.seedIfNeeded(in: modelContext)
        }
    }
}

#Preview {
    AlbumsListView()
        .modelContainer(for: [Album.self, Moment.self], inMemory: true)
}