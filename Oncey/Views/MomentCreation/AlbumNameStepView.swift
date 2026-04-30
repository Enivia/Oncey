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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.s6) {
                heroImageSection

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
            albumName: $albumName
        )
        .background(AppTheme.Colors.background)
    }
}

#Preview("Album Name") {
    MomentCreationAlbumNameStepPreview()
}
#endif
