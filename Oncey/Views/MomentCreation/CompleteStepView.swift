#if os(iOS)
import SwiftUI

struct CompleteStepView: View {
    let moment: Moment
    let namespace: Namespace.ID
    let elementPhases: MomentCreationTransitionElementPhases
    let reduceMotion: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.s6) {
                if reduceMotion {
                    MomentCardView(moment: moment, style: .styledCard1, renderMode: .full)
                        .momentCreationTransitionPhase(
                            phase(for: .completeCard),
                            reduceMotion: reduceMotion
                        )
                } else {
                    MomentCardView(moment: moment, style: .styledCard1, renderMode: .full)
                        .matchedGeometryEffect(id: "creation-note-card", in: namespace)
                        .momentCreationTransitionPhase(
                            phase(for: .completeCard),
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

private struct MomentCreationCompleteStepPreview: View {
    @Namespace private var previewNamespace

    private var moment: Moment {
        let album = Album(name: "Sunday Walk")
        return Moment(
            album: album,
            photo: "",
            note: "Soft light, still water, and a quiet walk.",
            createdAt: Date(timeIntervalSince1970: 1_713_628_800)
        )
    }

    var body: some View {
        CompleteStepView(
            moment: moment,
            namespace: previewNamespace,
            elementPhases: TransitionStateResolver.settledPhases(for: .workflow(.complete)),
            reduceMotion: false,
        )
        .background(AppTheme.Colors.background)
    }
}

#Preview("Complete") {
    MomentCreationCompleteStepPreview()
}
#endif
