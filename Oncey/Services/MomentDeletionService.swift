import Foundation
import SwiftData

enum MomentDeletionService {
    static func delete(_ moments: [Moment], in modelContext: ModelContext) throws {
        guard !moments.isEmpty else {
            return
        }

        let albumsToCheck = Array(Set(moments.compactMap(\ .album)))
        let photoPaths = moments.map(\.photo)

        for moment in moments {
            modelContext.delete(moment)
        }

        try modelContext.save()

        var clearedAlbumRatio = false
        for album in albumsToCheck where album.moments.isEmpty {
            guard album.ratio != nil else {
                continue
            }

            album.ratio = nil
            album.updatedAt = .now
            clearedAlbumRatio = true
        }

        if clearedAlbumRatio {
            try modelContext.save()
        }

        for path in photoPaths {
            AppImageStore.deleteImageIfManaged(at: path)
        }
    }
}