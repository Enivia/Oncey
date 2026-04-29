#if os(iOS)
import SwiftUI
import UIKit

struct AlbumNameStepView: View {
    let image: UIImage
    let namespace: Namespace.ID
    let usesHeroMatchedGeometry: Bool
    let focus: FocusState<MomentCreationFocusField?>.Binding
    let elementPhases: MomentCreationTransitionElementPhases
    let reduceMotion: Bool
    @Binding var albumName: String
    let onNext: () -> Void

    private var trimmedName: String {
        albumName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.s6) {
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

                    Button(action: onNext){
                        Text("Next").frame(maxWidth: .infinity).padding(.vertical, AppTheme.Spacing.s2)
                    }
                    .buttonBorderShape(.roundedRectangle(radius: AppTheme.CornerRadius.md))
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.Colors.accent)
                    .disabled(trimmedName.isEmpty)
                    .momentCreationTransitionPhase(
                        phase(for: .primaryButton),
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
    @Namespace private var previewNamespace

    var body: some View {
        AlbumNameStepView(
            image: UIImage(systemName: "photo") ?? UIImage(),
            namespace: previewNamespace,
            usesHeroMatchedGeometry: true,
            focus: $focusedField,
            elementPhases: TransitionStateResolver.settledPhases(for: .workflow(.albumName)),
            reduceMotion: false,
            albumName: $albumName,
            onNext: {}
        )
        .background(AppTheme.Colors.background)
    }
}

#Preview("Album Name") {
    MomentCreationAlbumNameStepPreview()
}
#endif
