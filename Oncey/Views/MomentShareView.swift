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

    private let stylePickerHeight: CGFloat = 272

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                MomentCardView(moment: moment, style: selectedStyle, renderMode: .full)
                    .frame(maxWidth: MomentCardLayout.fullCardWidth)
                    .frame(maxWidth: .infinity)
                    .shadow(color: .black.opacity(0.08), radius: 24, y: 12)

                if isPreparingShareExport {
                    ProgressView("Preparing share image...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Share")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Back", systemImage: "chevron.backward") {
                    dismiss()
                }
            }

            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Save") {
                    Task {
                        await saveToPhotoLibrary()
                    }
                }
                .disabled(isSaving || isPreparingShareExport)

                if let shareExportURL {
                    ShareLink(item: shareExportURL) {
                        Text("Share")
                    }
                } else {
                    Button("Share") {}
                        .disabled(true)
                }
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
        VStack(alignment: .leading, spacing: 14) {
            Divider()

            Text("Card Style")
                .font(.headline.weight(.semibold))
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(MomentCardStyle.allCases) { style in
                        stylePickerButton(for: style)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.top, 14)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, minHeight: stylePickerHeight, maxHeight: stylePickerHeight, alignment: .top)
        .background(.background)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func stylePickerButton(for style: MomentCardStyle) -> some View {
        Button {
            selectedStyle = style
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                MomentCardView(moment: moment, style: style, renderMode: .thumbnail)
                    .frame(width: MomentCardLayout.thumbnailCardWidth)
                    .shadow(color: .black.opacity(0.08), radius: 16, y: 8)

                Text(style.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .padding(8)
            .frame(width: MomentCardLayout.thumbnailCardWidth + 16, alignment: .leading)
            .background(selectedStyle == style ? Color.accentColor.opacity(0.12) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(selectedStyle == style ? Color.accentColor : Color.primary.opacity(0.06), lineWidth: selectedStyle == style ? 2 : 1)
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
#endif