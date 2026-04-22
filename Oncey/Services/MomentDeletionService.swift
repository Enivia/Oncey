import SwiftData

enum MomentDeletionService {
    static func delete(_ moments: [Moment], in modelContext: ModelContext) throws {
        guard !moments.isEmpty else {
            return
        }

        let photoPaths = moments.map(\.photo)

        for moment in moments {
            modelContext.delete(moment)
        }

        try modelContext.save()

        for path in photoPaths {
            AppImageStore.deleteImageIfManaged(at: path)
        }
    }
}