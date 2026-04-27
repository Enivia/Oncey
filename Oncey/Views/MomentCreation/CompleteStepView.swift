#if os(iOS)
import SwiftUI

struct CompleteStepView: View {
    let moment: Moment
    let reminderMessage: String?
    let namespace: Namespace.ID
    let onTimeline: () -> Void

    @State private var showsDetails = false

    private var detailTransition: AnyTransition {
        .move(edge: .bottom).combined(with: .opacity)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.s6) {
                MomentCardView(moment: moment, style: .styledCard1, renderMode: .full)
                    .matchedGeometryEffect(id: "creation-note-card", in: namespace)

                if showsDetails {
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
                    .transition(detailTransition)
                }

                if showsDetails {
                    Button(action: onTimeline){
                        Text("Timeline").frame(maxWidth: .infinity).padding(.vertical, AppTheme.Spacing.s2)
                    }
                    .buttonBorderShape(.roundedRectangle(radius: AppTheme.CornerRadius.md))
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.Colors.accent)
                    .transition(detailTransition)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.s6)
            .padding(.top, AppTheme.Spacing.s2)
            .padding(.bottom, AppTheme.Spacing.s6)
        }
        .onAppear {
            guard showsDetails == false else {
                return
            }

            withAnimation(.easeOut(duration: 0.24).delay(0.12)) {
                showsDetails = true
            }
        }
        .onDisappear {
            showsDetails = false
        }
    }
}

private struct MomentCreationCompleteStepPreview: View {
    @Namespace private var previewNamespace

    private var moment: Moment {
        let album = Album(name: "Sunday Walk")
        return Moment(
            album: album,
            photo: "",
            location: "West Lake, Hangzhou",
            note: "Soft light, still water, and a quiet walk.",
            createdAt: Date(timeIntervalSince1970: 1_713_628_800)
        )
    }

    var body: some View {
        CompleteStepView(
            moment: moment,
            reminderMessage: "Deal. I’ll remind you to come back on \(AppDateFormatters.momentTimestamp.string(from: Date.now.addingTimeInterval(60 * 60 * 24 * 90)))",
            namespace: previewNamespace,
            onTimeline: {}
        )
        .background(AppTheme.Colors.background)
    }
}

#Preview("Complete") {
    MomentCreationCompleteStepPreview()
}
#endif
