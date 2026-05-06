//
//  AlbumMomentsViewModel.swift
//  Oncey
//

import Foundation

struct AlbumMomentsViewModel {
    let album: Album

    var title: String {
        album.name
    }

    var moments: [Moment] {
        album.moments.sorted { $0.createdAt > $1.createdAt }
    }

    func resolvedCurrentMomentID(preferredCurrentMomentID: UUID?) -> UUID? {
        Self.resolvedCurrentMomentID(in: moments, preferredCurrentMomentID: preferredCurrentMomentID)
    }

    func resolvedCurrentMomentID(currentMomentID: UUID?, preferredCurrentMomentID: UUID?) -> UUID? {
        Self.resolvedCurrentMomentID(
            in: moments,
            currentMomentID: currentMomentID,
            preferredCurrentMomentID: preferredCurrentMomentID
        )
    }

    func timestampText(for moment: Moment) -> String {
        AppDateFormatters.momentTimestamp.string(from: moment.createdAt)
    }

    static func resolvedCurrentMomentID(in moments: [Moment], preferredCurrentMomentID: UUID?) -> UUID? {
        guard let firstMoment = moments.first else {
            return nil
        }

        guard let preferredCurrentMomentID,
              moments.contains(where: { $0.id == preferredCurrentMomentID }) else {
            return firstMoment.id
        }

        return preferredCurrentMomentID
    }

    static func resolvedCurrentMomentID(
        in moments: [Moment],
        currentMomentID: UUID?,
        preferredCurrentMomentID: UUID?
    ) -> UUID? {
        if let currentMomentID,
           moments.contains(where: { $0.id == currentMomentID }) {
            return currentMomentID
        }

        return resolvedCurrentMomentID(
            in: moments,
            preferredCurrentMomentID: preferredCurrentMomentID
        )
    }
}
