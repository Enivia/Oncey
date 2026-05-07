import SwiftUI

struct MomentYearPickerToolbarContent: ToolbarContent {
    let availableYears: [Int]
    let currentYear: Int?
    let onSelect: (Int) -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .bottomBar) {
            Menu {
                ForEach(availableYears, id: \.self) { year in
                    Button {
                        onSelect(year)
                    } label: {
                        if year == currentYear {
                            Label(String(year), systemImage: "checkmark")
                        } else {
                            Text(String(year))
                        }
                    }
                }
            } label: {
                HStack(spacing: AppTheme.Spacing.s2) {
                    Image(systemName: "calendar")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.Colors.accent)

                    Text(currentYear.map(String.init) ?? "--")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.Colors.accent)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }
            .menuOrder(.fixed)
            .accessibilityLabel("Select year")
        }
    }
}