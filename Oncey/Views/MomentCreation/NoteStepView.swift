#if os(iOS)
import SwiftUI
import UIKit

struct NoteStepView: View {
    let image: UIImage
    let namespace: Namespace.ID
    let usesHeroMatchedGeometry: Bool
    let focus: FocusState<MomentCreationFocusField?>.Binding
    let elementPhases: MomentCreationTransitionElementPhases
    let reduceMotion: Bool
    @Binding var note: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.s6) {
                heroImageSection

                VStack(alignment: .leading, spacing: AppTheme.Spacing.s3) {
                    let noteCard = ZStack(alignment: .topLeading) {
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
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous)
                            .stroke(AppTheme.Colors.border, lineWidth: 1)
                    }

                    if reduceMotion {
                        noteCard
                            .momentCreationTransitionPhase(
                                phase(for: .noteCard),
                                reduceMotion: reduceMotion
                            )
                    } else {
                        noteCard
                            .matchedGeometryEffect(id: "creation-note-card", in: namespace)
                            .momentCreationTransitionPhase(
                                phase(for: .noteCard),
                                reduceMotion: reduceMotion
                            )
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.s6)
            .padding(.top, AppTheme.Spacing.s2)
            .padding(.bottom, AppTheme.Spacing.s6)
        }
    }

    private func phase(
        for element: MomentCreationTransitionElement
    ) -> MomentCreationTransitionElementPhase {
        elementPhases[element] ?? .hiddenBelow
    }

    private var heroImageSection: some View {
        HeroImageView(
            image: image,
            maxHeight: 500,
            namespace: namespace,
            geometryID: "creation-hero-image",
            usesMatchedGeometry: usesHeroMatchedGeometry && !reduceMotion
        )
        .momentCreationTransitionPhase(
            phase(for: .heroImage),
            reduceMotion: reduceMotion
        )
        .frame(height: heroReservedHeight, alignment: .top)
        .clipped()
    }

    private var heroReservedHeight: CGFloat {
        switch phase(for: .heroImage) {
        case .visible:
            return 500
        case .hiddenBelow, .hiddenAbove:
            return 0
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
            usesHeroMatchedGeometry: true,
            focus: $focusedField,
            elementPhases: TransitionStateResolver.settledPhases(for: .workflow(.note)),
            reduceMotion: false,
            note: $note
        )
        .background(AppTheme.Colors.background)
    }
}

#Preview("Note") {
    MomentCreationNoteStepPreview()
}
#endif
