//
//  MomentsTimelineView.swift
//  Oncey
//

import SwiftUI

struct MomentsTimelineView: View {
    let album: Album

    private var viewModel: MomentsTimelineViewModel {
        MomentsTimelineViewModel(album: album)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 30) {
                ForEach(Array(viewModel.moments.enumerated()), id: \.element.id) { index, moment in
                    MomentTimelineRowView(
                        moment: moment,
                        timestampText: viewModel.timestampText(for: moment),
                        isFirst: index == 0,
                        isLast: index == viewModel.moments.count - 1
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 36)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    let album = Album(name: "Weekend Escape")
    let firstMoment = Moment(album: album, photo: "", location: "Kyoto, Japan", createdAt: .now)
    let secondMoment = Moment(album: album, photo: "", location: "Kyoto, Japan", createdAt: .now.addingTimeInterval(-7_200))
    album.moments = [firstMoment, secondMoment]

    NavigationStack {
        MomentsTimelineView(album: album)
    }
}