#if os(iOS)
import SwiftUI
import UIKit

struct NoteStepView: View {
    let image: UIImage
    let namespace: Namespace.ID
    let focus: FocusState<MomentCreationFocusField?>.Binding
    @Binding var note: String
    let onNext: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.s6) {
                HeroImageView(
                    image: image,
                    maxHeightRatio: 0.33,
                    namespace: namespace,
                    geometryID: "creation-hero-image"
                )

                VStack(alignment: .leading, spacing: AppTheme.Spacing.s3) {
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $note)
                            .frame(minHeight: 120)
                            .scrollContentBackground(.hidden)
                            .padding(.horizontal, AppTheme.Spacing.s4)
                            .padding(.vertical, AppTheme.Spacing.s2)
                            .background(AppTheme.Colors.surface)
                            .focused(focus, equals: .note)

                        if note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("What do you want to say in this moment?")
                                .font(.body)
                                .foregroundStyle(AppTheme.Colors.textSecondary.opacity(0.75))
                                .padding(.horizontal, AppTheme.Spacing.s5)
                                .padding(.vertical, AppTheme.Spacing.s5)
                                .allowsHitTesting(false)
                        }
                    }
                    .matchedGeometryEffect(id: "creation-note-card", in: namespace)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous)
                            .stroke(AppTheme.Colors.border, lineWidth: 1)
                    }

                    Button(action: onNext){
                        Text("Next").frame(maxWidth: .infinity).padding(.vertical, AppTheme.Spacing.s2)
                    }
                    .buttonBorderShape(.roundedRectangle(radius: AppTheme.CornerRadius.md))
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.Colors.accent)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.s6)
            .padding(.top, AppTheme.Spacing.s2)
            .padding(.bottom, AppTheme.Spacing.s6)
        }
    }
}

private struct MomentCreationNoteStepPreview: View {
    @State private var note = "Soft light, still water, and a quiet walk."
    @FocusState private var focusedField: MomentCreationFocusField?
    @Namespace private var previewNamespace

    var body: some View {
        NoteStepView(
            image: UIImage(systemName: "photo") ?? UIImage(),
            namespace: previewNamespace,
            focus: $focusedField,
            note: $note,
            onNext: {}
        )
        .background(AppTheme.Colors.background)
    }
}

#Preview("Note") {
    MomentCreationNoteStepPreview()
}
#endif
