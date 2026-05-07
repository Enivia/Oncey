import SwiftUI

struct MomentComparisonPicker: View {
    let moments: [Moment]
    let leadingMomentID: UUID?
    let trailingMomentID: UUID?
    let activeSide: MomentComparisonState.Side?
    let onSelect: (UUID) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .center, spacing: AppTheme.Spacing.s4) {
                ForEach(moments) { moment in
                    MomentComparisonPickerItem(
                        moment: moment,
                        selectionBorder: selectionBorder(for: moment.id),
                        isDisabled: isDisabled(moment.id)
                    ) {
                        onSelect(moment.id)
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.s6)
            .padding(.top, AppTheme.Spacing.s8)
            .padding(.bottom, AppTheme.Spacing.s2)
        }
        .defaultScrollAnchor(.center)
        .frame(maxWidth: .infinity)
        .background(AppTheme.Colors.surface)
    }

    private func selectionBorder(for momentID: UUID) -> Color? {
        if momentID == leadingMomentID {
            return AppTheme.Colors.accentSoft
        }

        if momentID == trailingMomentID {
            return AppTheme.Colors.secondarySoft
        }

        return nil
    }

    private func isDisabled(_ momentID: UUID) -> Bool {
        switch activeSide {
        case .leading:
            return momentID == trailingMomentID
        case .trailing:
            return momentID == leadingMomentID
        case nil:
            return false
        }
    }
}

private struct MomentComparisonPickerItem: View {
    let moment: Moment
    let selectionBorder: Color?
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.Spacing.s2) {
                LocalPhotoView(path: moment.photo)
                    .frame(width: 100, height: 100)

                Text(AppDateFormatters.momentCompactDate.string(from: moment.createdAt))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .padding(AppTheme.Spacing.s2)
            .background(AppTheme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.sm, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.sm, style: .continuous)
                    .stroke(selectionBorder ?? AppTheme.Colors.border, lineWidth: 2)
            }
            .opacity(isDisabled && selectionBorder == nil ? 0.35 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}
