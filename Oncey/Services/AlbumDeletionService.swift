import Foundation
import SwiftData

enum AlbumDeletionService {
    static func delete(_ album: Album, in modelContext: ModelContext) throws {
        let photoPaths = album.moments.map(\ .photo)
        let outlinePath = album.templateOutlinePath

        modelContext.delete(album)
        try modelContext.save()

        for path in photoPaths {
            AppImageStore.deleteImageIfManaged(at: path)
        }

        AppImageStore.deleteOutlineIfManaged(at: outlinePath)
    }
}