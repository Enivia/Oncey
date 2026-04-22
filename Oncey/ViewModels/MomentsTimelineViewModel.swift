//
//  MomentsTimelineViewModel.swift
//  Oncey
//

import Foundation

struct MomentsTimelineViewModel {
    let album: Album

    var title: String {
        album.name
    }

    var moments: [Moment] {
        album.moments.sorted { $0.createdAt > $1.createdAt }
    }

    func timestampText(for moment: Moment) -> String {
        AppDateFormatters.momentTimestamp.string(from: moment.createdAt)
    }
}