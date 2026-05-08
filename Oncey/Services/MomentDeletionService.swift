import Foundation
import SwiftData

enum MomentDeletionService {
    static func delete(
        _ moments: [Moment],
        in modelContext: ModelContext,
        updatedAt: Date = .now,
        reminderClient: AlbumReminderClient = AlbumReminderClient.live()
    ) throws {
        guard !moments.isEmpty else {
            return
        }

        let albumsToCheck = Array(Set(moments.compactMap(\ .album)))
        let photoPaths = moments.map(\.photo)

        for moment in moments {
            modelContext.delete(moment)
        }

        try modelContext.save()

        var updatedAlbums = false
        var albumsToUnscheduleReminder: [Album] = []
        for album in albumsToCheck where album.moments.isEmpty {
            var didUpdateAlbum = false

            if album.ratio != nil {
                album.ratio = nil
                didUpdateAlbum = true
            }

            if album.hasReminder,
               let remindValue = album.remindValue,
               let remindUnit = album.remindUnit {
                AlbumReminderService.storeReminderConfiguration(
                    on: album,
                    value: remindValue,
                    unit: remindUnit,
                    updatedAt: updatedAt,
                    removesScheduledReminder: false,
                    client: reminderClient
                )
                albumsToUnscheduleReminder.append(album)
                didUpdateAlbum = true
            } else if didUpdateAlbum {
                album.updatedAt = updatedAt
            }

            updatedAlbums = updatedAlbums || didUpdateAlbum
        }

        if updatedAlbums {
            try modelContext.save()
        }

        for album in albumsToUnscheduleReminder {
            AlbumReminderService.removeScheduledReminder(for: album, client: reminderClient)
        }

        for path in photoPaths {
            AppImageStore.deleteImageIfManaged(at: path)
        }
    }
}