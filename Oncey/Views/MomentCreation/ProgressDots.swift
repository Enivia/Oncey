#if os(iOS)
import SwiftUI

struct ProgressDots: View {
    let steps: [MomentCreationWorkflowStep]
    let currentStep: MomentCreationWorkflowStep

    private var currentIndex: Int {
        steps.firstIndex(of: currentStep) ?? 0
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.s2) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, _ in
                Circle()
                    .fill(index <= currentIndex ? AppTheme.Colors.accent : AppTheme.Colors.divider)
                    .frame(width: 7, height: 7)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
#endif
