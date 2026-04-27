#if os(iOS)
import SwiftUI
import UIKit

struct ReminderStepView: View {
    let image: UIImage
    let note: String
    let namespace: Namespace.ID
    @Binding var reminderValue: Int
    @Binding var reminderUnit: AlbumReminderUnit
    let reminderDateText: String
    let onSkip: () -> Void
    let onDeal: () -> Void

    private var trimmedNote: String {
        note.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.s6) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.s4) {
                    HeroImageView(
                        image: image,
                        maxHeightRatio: 0.33,
                        namespace: namespace,
                        geometryID: "creation-hero-image"
                    )

                    if trimmedNote.isEmpty == false {
                        Text(trimmedNote)
                            .font(.body)
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                            .lineLimit(2)
                    }
                }
                .matchedGeometryEffect(id: "creation-note-card", in: namespace)
                .padding(AppTheme.Spacing.s5)
                .background(AppTheme.Colors.surface, in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous))
                .shadow(color: AppTheme.Colors.shadow, radius: AppTheme.Shadow.softRadius, y: AppTheme.Shadow.softYOffset)

                Text("How often would you like to leave a memory here?")
                    .font(.title3)

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

                Text("I’ll remind you to come back on \(reminderDateText)")
                    .font(.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)

                VStack(spacing: AppTheme.Spacing.s5) {
                    Button(action: onDeal) {
                        Label("Deal", systemImage: "bell")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.Colors.accent)
                    
                    Button(action: onSkip) {
                        Label("No Reminder", systemImage: "bell.slash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(AppTheme.Colors.accent)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.s6)
            .padding(.top, AppTheme.Spacing.s2)
            .padding(.bottom, AppTheme.Spacing.s6)
        }
    }
}

private struct MomentCreationReminderStepPreview: View {
    @State private var reminderValue = 3
    @State private var reminderUnit: AlbumReminderUnit = .month
    @Namespace private var previewNamespace

    var body: some View {
        ReminderStepView(
            image: UIImage(systemName: "photo") ?? UIImage(),
            note: "Soft light, still water, and a quiet walk.",
            namespace: previewNamespace,
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
