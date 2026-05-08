import SwiftData
import SwiftUI

struct AlbumReminderEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let album: Album
    let reminderClient: AlbumReminderClient

    @State private var reminderValue: Int
    @State private var reminderUnit: AlbumReminderUnit
    @State private var errorMessage: String?
    @State private var isPresentingError = false
    @State private var isSaving = false

    init(
        album: Album,
        reminderClient: AlbumReminderClient = AlbumReminderClient.live()
    ) {
        self.album = album
        self.reminderClient = reminderClient
        _reminderValue = State(initialValue: album.remindValue ?? 1)
        _reminderUnit = State(initialValue: album.remindUnit ?? .month)
    }

    var body: some View {
        ZStack {
            AppPageBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.s6) {
                    AlbumReminderConfigurationContent(
                        reminderValue: $reminderValue,
                        reminderUnit: $reminderUnit,
                        reminderBaseDate: latestMomentCreatedAt
                    )

                    Button {
                        clearReminder()
                    } label: {
                        Label("No Reminder", systemImage: "bell.slash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(AppTheme.Colors.accent)
                    .disabled(isSaving)
                }
                .padding(.horizontal, AppTheme.Spacing.s6)
                .padding(.top, AppTheme.Spacing.s4)
                .padding(.bottom, AppTheme.Spacing.s6)
            }
        }
        .navigationTitle("Reminder")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
                .accessibilityLabel("Close")
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        await saveReminder()
                    }
                } label: {
                    Image(systemName: "checkmark")
                }
                .tint(AppTheme.Colors.accent)
                .buttonStyle(.glassProminent)
                .disabled(isSaving)
                .accessibilityLabel("Save reminder")
            }
        }
        .alert("Couldn't save reminder", isPresented: $isPresentingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
    }

    private var latestMomentCreatedAt: Date? {
        album.moments.max { lhs, rhs in
            if lhs.createdAt == rhs.createdAt {
                return lhs.updatedAt < rhs.updatedAt
            }

            return lhs.createdAt < rhs.createdAt
        }?.createdAt
    }

    @MainActor
    private func saveReminder() async {
        guard !isSaving else {
            return
        }

        isSaving = true
        let updatedAt = Date.now
        let originalReminderValue = album.remindValue
        let originalReminderUnit = album.remindUnit
        let originalRemindAt = album.remindAt
        let originalUpdatedAt = album.updatedAt
        var didPersistChanges = false

        do {
            if let latestMomentCreatedAt {
                _ = try AlbumReminderService.storeReminder(
                    on: album,
                    value: reminderValue,
                    unit: reminderUnit,
                    baseDate: latestMomentCreatedAt,
                    updatedAt: updatedAt
                )
                try modelContext.save()
                didPersistChanges = true
                _ = try await AlbumReminderService.scheduleStoredReminder(for: album, client: reminderClient)
            } else {
                AlbumReminderService.storeReminderConfiguration(
                    on: album,
                    value: reminderValue,
                    unit: reminderUnit,
                    updatedAt: updatedAt,
                    removesScheduledReminder: false,
                    client: reminderClient
                )
                try modelContext.save()
                didPersistChanges = true
                AlbumReminderService.removeScheduledReminder(for: album, client: reminderClient)
            }

            dismiss()
        } catch {
            if !didPersistChanges {
                album.remindValue = originalReminderValue
                album.remindUnit = originalReminderUnit
                album.remindAt = originalRemindAt
                album.updatedAt = originalUpdatedAt
                errorMessage = error.localizedDescription
            } else {
                errorMessage = "Reminder was saved, but the system notification couldn't be updated."
            }
            isPresentingError = true
        }

        isSaving = false
    }

    private func clearReminder() {
        guard !isSaving else {
            return
        }

        isSaving = true
        let originalReminderValue = album.remindValue
        let originalReminderUnit = album.remindUnit
        let originalRemindAt = album.remindAt
        let originalUpdatedAt = album.updatedAt

        do {
            album.remindValue = nil
            album.remindUnit = nil
            album.remindAt = nil
            album.updatedAt = .now

            try modelContext.save()
            AlbumReminderService.removeScheduledReminder(for: album, client: reminderClient)
            dismiss()
        } catch {
            album.remindValue = originalReminderValue
            album.remindUnit = originalReminderUnit
            album.remindAt = originalRemindAt
            album.updatedAt = originalUpdatedAt
            errorMessage = error.localizedDescription
            isPresentingError = true
        }

        isSaving = false
    }
}