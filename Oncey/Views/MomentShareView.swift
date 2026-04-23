#if canImport(UIKit)
import SwiftUI

struct MomentShareView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.displayScale) private var displayScale

    let moment: Moment

    @State private var selectedStyle: MomentCardStyle = .styledCard1
    @State private var shareExportURL: URL?
    @State private var isPreparingShareExport = false
    @State private var isSaving = false
    @State private var resultAlertTitle = ""
    @State private var resultAlertMessage = ""
    @State private var isPresentingResultAlert = false

    var body: some View {
        ZStack {
            AppPageBackground()

            GeometryReader { proxy in
                ScrollView(.vertical) {
                    MomentCardView(moment: moment, style: selectedStyle, renderMode: .full)
                        .padding(AppTheme.Spacing.s6)
                        .frame(minWidth: proxy.size.width, minHeight: proxy.size.height, alignment: .center)
                }
                .defaultScrollAnchor(.center)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Back", systemImage: "chevron.backward") {
                    dismiss()
                }
            }

            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Save", systemImage: "square.and.arrow.down") {
                    Task {
                        await saveToPhotoLibrary()
                    }
                }
                .disabled(isSaving || isPreparingShareExport)

                Button("Share", systemImage: "square.and.arrow.up"){}
            }
        }
        .safeAreaInset(edge: .bottom) {
            stylePicker
        }
        .task(id: selectedStyle) {
            await prepareShareExport()
        }
        .alert(resultAlertTitle, isPresented: $isPresentingResultAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(resultAlertMessage)
        }
    }

    private var stylePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: AppTheme.Spacing.s4) {
                ForEach(MomentCardStyle.allCases) { style in
                    stylePickerButton(for: style)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.s6)
            .padding(.vertical, AppTheme.Spacing.s4)
        }
        .background(AppTheme.Colors.surface)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppTheme.Colors.border)
                .frame(height: 1)
        }
    }

    private func stylePickerButton(for style: MomentCardStyle) -> some View {
        Button {
            selectedStyle = style
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                MomentCardView(moment: moment, style: style, renderMode: .thumbnail)
                    .frame(width: 120)
            }
            .padding(AppTheme.Spacing.s2)
            .background(selectedStyle == style ? AppTheme.Colors.accentSoft : AppTheme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous)
                    .stroke(selectedStyle == style ? AppTheme.Colors.accentStroke : AppTheme.Colors.border, lineWidth: selectedStyle == style ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
    }

    private func prepareShareExport() async {
        isPreparingShareExport = true
        shareExportURL = nil

        do {
            shareExportURL = try MomentShareExportService.exportFile(moment: moment, style: selectedStyle, scale: displayScale)
        } catch {
            presentResult(title: "Couldn't prepare share image", message: error.localizedDescription)
        }

        isPreparingShareExport = false
    }

    private func saveToPhotoLibrary() async {
        guard !isSaving else {
            return
        }

        isSaving = true

        do {
            try await MomentShareExportService.saveImageToPhotoLibrary(moment: moment, style: selectedStyle, scale: displayScale)
            presentResult(title: "Saved", message: "The rendered card has been saved to your photo library.")
        } catch {
            presentResult(title: "Couldn't save image", message: error.localizedDescription)
        }

        isSaving = false
    }

    private func presentResult(title: String, message: String) {
        resultAlertTitle = title
        resultAlertMessage = message
        isPresentingResultAlert = true
    }
}

#Preview {
    let album = Album(name: "Tokyo Trip 2024")
    let moment = Moment(
        album: album,
        photo: "",
        location: "Shibuya, Tokyo",
        note: "Golden hour at the famous crossing — the city alive with evening rush.",
        createdAt: Date(timeIntervalSince1970: 1_713_628_800)
    )

    NavigationStack {
        MomentShareView(moment: moment)
    }
}
#endif
