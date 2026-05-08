import SwiftUI

struct AlbumReminderConfigurationContent: View {
    @Binding var reminderValue: Int
    @Binding var reminderUnit: AlbumReminderUnit

    let reminderBaseDate: Date?
    let pickerWrapper: ((AnyView) -> AnyView)?
    let descriptionWrapper: ((AnyView) -> AnyView)?

    init(
        reminderValue: Binding<Int>,
        reminderUnit: Binding<AlbumReminderUnit>,
        reminderBaseDate: Date?,
        pickerWrapper: ((AnyView) -> AnyView)? = nil,
        descriptionWrapper: ((AnyView) -> AnyView)? = nil
    ) {
        _reminderValue = reminderValue
        _reminderUnit = reminderUnit
        self.reminderBaseDate = reminderBaseDate
        self.pickerWrapper = pickerWrapper
        self.descriptionWrapper = descriptionWrapper
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s4) {
            wrappedPickerSection
            wrappedDescriptionSection
        }
    }

    private var wrappedPickerSection: AnyView {
        let pickerSection = AnyView(
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
            .background(
                AppTheme.Colors.surface,
                in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous)
            )
        )

        return pickerWrapper?(pickerSection) ?? pickerSection
    }

    private var wrappedDescriptionSection: AnyView {
        let descriptionSection = AnyView(
            Text(reminderDescription)
                .font(.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)
        )

        return descriptionWrapper?(descriptionSection) ?? descriptionSection
    }

    private var reminderDescription: String {
        guard let reminderBaseDate,
              let reminderDate = AlbumReminderService.reminderDate(
                from: reminderBaseDate,
                value: reminderValue,
                unit: reminderUnit
              ) else {
            return "Reminders will turn on after your first entry."
        }

        let reminderDateText = AppDateFormatters.momentTimestamp.string(from: reminderDate)
        return "I’ll remind you to come back on \(reminderDateText)"
    }
}