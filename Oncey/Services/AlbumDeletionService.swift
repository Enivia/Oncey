import Foundation
import SwiftData

enum AlbumDeletionService {
    static func delete(_ album: Album, in modelContext: ModelContext) throws {
        let photoPaths = album.moments.map(\ .photo)

        modelContext.delete(album)
        try modelContext.save()

        for path in photoPaths {
            AppImageStore.deleteImageIfManaged(at: path)
        }
    }
}
