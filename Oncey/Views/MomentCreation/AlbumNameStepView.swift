#if os(iOS)
import SwiftUI

struct AlbumNameStepView: View {
    let focus: FocusState<MomentCreationFocusField?>.Binding
    let elementPhases: MomentCreationTransitionElementPhases
    let reduceMotion: Bool
    @Binding var albumName: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.s6) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.s3) {
                    VStack(spacing: 0) {
                        TextField("Name this moment", text: $albumName)
                            .textInputAutocapitalization(.words)
                            .submitLabel(.done)
                            .focused(focus, equals: .albumName)
                            .padding(.horizontal, AppTheme.Spacing.s4)
                            .frame(height: 56)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous)
                            .fill(AppTheme.Colors.surface)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous)
                            .stroke(AppTheme.Colors.border, lineWidth: 1)
                    }
                    .momentCreationTransitionPhase(
                        phase(for: .albumNameField),
                        reduceMotion: reduceMotion
                    )
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
}

private struct MomentCreationAlbumNameStepPreview: View {
    @State private var albumName = "Name"
    @FocusState private var focusedField: MomentCreationFocusField?

    var body: some View {
        AlbumNameStepView(
            focus: $focusedField,
            elementPhases: TransitionStateResolver.settledPhases(for: .workflow(.albumName)),
            reduceMotion: false,
            albumName: $albumName
        )
        .background(AppTheme.Colors.background)
    }
}

#Preview("Album Name") {
    MomentCreationAlbumNameStepPreview()
}
#endif
