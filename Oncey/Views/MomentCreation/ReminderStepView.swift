#if os(iOS)
import SwiftUI
import UIKit

struct ReminderStepView: View {
    let elementPhases: MomentCreationTransitionElementPhases
    let reduceMotion: Bool
    @Binding var reminderValue: Int
    @Binding var reminderUnit: AlbumReminderUnit
    let reminderDateText: String
    let onSkip: () -> Void
    let onDeal: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.s6) {
                Text("How often would you like to leave a memory here?")
                    .font(.title3)
                    .momentCreationTransitionPhase(
                        phase(for: .reminderTitle),
                        reduceMotion: reduceMotion
                    )

                HStack(spacing: AppTheme.Spacing.s3) {
                    Picker("Value", selection: $reminderValue) {
                        ForEach(1...30, id: \.self) { value in
                            Text("\(value)").tag(value)
                        }
                    }
                    .pickerStyle(.wheel)

                    Picker("Unit", selection: $reminderUnit) {
                        ForEach(AlbumReminderUnit.allCases) { unit in
                            Text(unit.title).tag(unit)
                        }
                    }
                    .pickerStyle(.wheel)
                }
                .frame(height: 160)
                .background(AppTheme.Colors.surface, in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous))
                .momentCreationTransitionPhase(
                    phase(for: .reminderPicker),
                    reduceMotion: reduceMotion
                )

                Text("I’ll remind you to come back on \(reminderDateText)")
                    .font(.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .momentCreationTransitionPhase(
                        phase(for: .reminderDescription),
                        reduceMotion: reduceMotion
                    )

                VStack(spacing: AppTheme.Spacing.s5) {
                    Button(action: onDeal) {
                        Label("Deal", systemImage: "bell")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.Colors.accent)
                    .momentCreationTransitionPhase(
                        phase(for: .reminderPrimaryButton),
                        reduceMotion: reduceMotion
                    )
                    
                    Button(action: onSkip) {
                        Label("No Reminder", systemImage: "bell.slash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(AppTheme.Colors.accent)
                    .momentCreationTransitionPhase(
                        phase(for: .reminderSecondaryButton),
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

private struct MomentCreationReminderStepPreview: View {
    @State private var reminderValue = 3
    @State private var reminderUnit: AlbumReminderUnit = .month
    @Namespace private var previewNamespace

    var body: some View {
        ReminderStepView(
            elementPhases: TransitionStateResolver.settledPhases(for: .workflow(.reminder)),
            reduceMotion: false,
            reminderValue: $reminderValue,
            reminderUnit: $reminderUnit,
            reminderDateText: AppDateFormatters.momentTimestamp.string(from: Date.now.addingTimeInterval(60 * 60 * 24 * 90)),
            onSkip: {},
            onDeal: {}
        )
        .background(AppTheme.Colors.background)
    }
}

#Preview("Reminder") {
    MomentCreationReminderStepPreview()
}
#endif
