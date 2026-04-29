#if os(iOS)
import SwiftUI

struct CompleteStepView: View {
    let moment: Moment
    let reminderMessage: String?
    let namespace: Namespace.ID
    let elementPhases: MomentCreationTransitionElementPhases
    let reduceMotion: Bool
    let onTimeline: () -> Void

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

                VStack(alignment: .leading, spacing: AppTheme.Spacing.s3) {
                    Text("Moment captured")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppTheme.Colors.textPrimary)

                    if let reminderMessage {
                        Text(reminderMessage)
                            .font(.body)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                }
                .momentCreationTransitionPhase(
                    phase(for: .completeTimeline),
                    reduceMotion: reduceMotion
                )

                Button(action: onTimeline){
                    Text("Timeline").frame(maxWidth: .infinity).padding(.vertical, AppTheme.Spacing.s2)
                }
                .buttonBorderShape(.roundedRectangle(radius: AppTheme.CornerRadius.md))
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.Colors.accent)
                .momentCreationTransitionPhase(
                    phase(for: .completeTimeline),
                    reduceMotion: reduceMotion
                )
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
            reminderMessage: "Deal. I’ll remind you to come back on \(AppDateFormatters.momentTimestamp.string(from: Date.now.addingTimeInterval(60 * 60 * 24 * 90)))",
            namespace: previewNamespace,
            elementPhases: TransitionStateResolver.settledPhases(for: .workflow(.complete)),
            reduceMotion: false,
            onTimeline: {}
        )
        .background(AppTheme.Colors.background)
    }
}

#Preview("Complete") {
    MomentCreationCompleteStepPreview()
}
#endif
