import Foundation
import SwiftData

enum MomentNoteUpdateService {
    static func update(_ moment: Moment, note: String, in modelContext: ModelContext, updatedAt: Date) throws {
        try update(moment, note: note, updatedAt: updatedAt) {
            try modelContext.save()
        }
    }

    static func update(_ moment: Moment, note: String, updatedAt: Date, save: () throws -> Void) throws {
        let previousNote = moment.note
        let previousUpdatedAt = moment.updatedAt

        moment.note = normalized(note)
        moment.updatedAt = updatedAt

        do {
            try save()
        } catch {
            moment.note = previousNote
            moment.updatedAt = previousUpdatedAt
            throw error
        }
    }

    private static func normalized(_ note: String) -> String {
        note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "" : note
    }
}