import SwiftData
import SwiftUI

struct MomentNoteEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let moment: Moment

    @State private var note: String
    @State private var errorMessage: String?
    @State private var isPresentingError = false
    @State private var isSaving = false

    init(moment: Moment) {
        self.moment = moment
        _note = State(initialValue: moment.note)
    }

    var body: some View {
        ZStack {
            AppPageBackground()

            VStack(spacing: AppTheme.Spacing.s5) {
                noteEditor
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, AppTheme.Spacing.s6)
            .padding(.top, AppTheme.Spacing.s4)
            .padding(.bottom, AppTheme.Spacing.s6)
        }
        .navigationTitle("Note")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close", systemImage: "xmark") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("Confirm", systemImage: "checkmark") {
                    save()
                }
                .tint(AppTheme.Colors.accent)
                .buttonStyle(.glassProminent)
                .disabled(isSaving)
            }
        }
        .alert("Couldn't save note", isPresented: $isPresentingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
    }

    private var noteEditor: some View {
        ZStack(alignment: .topLeading) {
            NoteEditorBackground()

            TextEditor(text: $note)
                .frame(minHeight: 220)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, AppTheme.Spacing.s4)
                .padding(.vertical, AppTheme.Spacing.s2)
                .background(Color.clear)

            if note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("Add a note to this moment...")
                    .font(.body)
                    .foregroundStyle(AppTheme.Colors.textSecondary.opacity(0.7))
                    .padding(.horizontal, AppTheme.Spacing.s5)
                    .padding(.vertical, AppTheme.Spacing.s5)
                    .allowsHitTesting(false)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous))
    }

    private func save() {
        guard !isSaving else {
            return
        }

        isSaving = true

        do {
            try MomentNoteUpdateService.update(moment, note: note, in: modelContext, updatedAt: .now)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            isPresentingError = true
        }

        isSaving = false
    }
}

private struct NoteEditorBackground: View {
    private let lineSpacing: CGFloat = 32
    private let topInset: CGFloat = 36

    var body: some View {
        Canvas(rendersAsynchronously: true) { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(AppTheme.Colors.surface))

            for y in stride(from: topInset, through: size.height, by: lineSpacing) {
                var line = Path()
                line.move(to: CGPoint(x: AppTheme.Spacing.s4, y: y))
                line.addLine(to: CGPoint(x: size.width - AppTheme.Spacing.s4, y: y))
                context.stroke(line, with: .color(AppTheme.Colors.accentSoft.opacity(0.1)), lineWidth: 1)
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Album.self, Moment.self, configurations: config)

    let album = Album(name: "Tokyo Trip 2024")
    container.mainContext.insert(album)

    let moment = Moment(
        album: album,
        photo: "",
        note: "Golden hour at the famous crossing — the city alive with evening rush.",
        createdAt: Date(timeIntervalSince1970: 1_713_628_800)
    )
    container.mainContext.insert(moment)

    return NavigationStack {
        MomentNoteEditorSheet(moment: moment)
    }
    .modelContainer(container)
}
