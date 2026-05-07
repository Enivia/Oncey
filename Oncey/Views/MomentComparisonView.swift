import SwiftUI

struct MomentComparisonView: View {
    let album: Album

    private let currentMomentID: UUID?
    @State private var comparisonState: MomentComparisonState

    init(album: Album, currentMomentID: UUID?) {
        self.album = album
        self.currentMomentID = currentMomentID
        _comparisonState = State(
            initialValue: MomentComparisonState(
                moments: album.moments,
                currentMomentID: currentMomentID
            )
        )
    }

    var body: some View {
        ZStack {
            AppPageBackground()

            if let leadingMoment = comparisonState.leadingMoment,
               let trailingMoment = comparisonState.trailingMoment {
                GeometryReader { proxy in
                    ScrollView(.vertical) {
                        VStack(spacing: AppTheme.Spacing.s6) {
                            Spacer(minLength: AppTheme.Spacing.s6)
                            comparisonSection(
                                leadingMoment: leadingMoment,
                                trailingMoment: trailingMoment
                            )
                            Spacer(minLength: AppTheme.Spacing.s6)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(
                            minHeight: max(0, proxy.size.height - pickerHeight),
                            alignment: .center
                        )
                    }
                    .defaultScrollAnchor(.center)
                    .scrollIndicators(.hidden)
                }
            } else {
                ContentUnavailableView(
                    "Need two moments to compare",
                    systemImage: "square.and.line.vertical.and.square.filled",
                    description: Text("Add another moment in this album to view the comparison slider.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Compare")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if comparisonState.isPickerExpanded {
                MomentComparisonPicker(
                    moments: comparisonState.moments,
                    leadingMomentID: comparisonState.leadingMomentID,
                    trailingMomentID: comparisonState.trailingMomentID,
                    activeSide: comparisonState.activeSide,
                    onSelect: { comparisonState.selectMoment(id: $0) }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.24), value: comparisonState.isPickerExpanded)
        .onChange(of: album.moments.map(\ .id)) { _, _ in
            comparisonState.syncMoments(album.moments, preferredCurrentMomentID: currentMomentID)
        }
    }

    private var pickerHeight: CGFloat {
        comparisonState.isPickerExpanded ? 200 : 0
    }

    private func comparisonSection(leadingMoment: Moment, trailingMoment: Moment) -> some View {
        VStack(spacing: AppTheme.Spacing.s4) {
            MomentComparisonSlider(
                leadingMoment: leadingMoment,
                trailingMoment: trailingMoment,
                aspectRatio: resolvedAspectRatio(leadingMoment: leadingMoment, trailingMoment: trailingMoment),
                activeSide: comparisonState.activeSide,
                onTapSide: { comparisonState.presentPicker(for: $0) }
            )

            HStack(alignment: .center, spacing: AppTheme.Spacing.s4) {
                Text(AppDateFormatters.momentCompactDate.string(from: leadingMoment.createdAt))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(AppDateFormatters.momentCompactDate.string(from: trailingMoment.createdAt))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(AppTheme.Colors.textPrimary)
            .padding(.horizontal, AppTheme.Spacing.s6)
        }
    }

    private func resolvedAspectRatio(leadingMoment: Moment, trailingMoment: Moment) -> CGFloat {
        let moments = [leadingMoment, trailingMoment]

        for moment in moments {
            guard let size = ImageResourceService.imageSize(from: moment.photo),
                  size.width > 0,
                  size.height > 0 else {
                continue
            }

            return size.width / size.height
        }

        if let templatePhotoAspectRatio = album.templatePhotoAspectRatio,
           templatePhotoAspectRatio > 0 {
            return CGFloat(templatePhotoAspectRatio)
        }

        return MomentPhotoLayoutResolver.displayAspectRatio(
            imageSize: nil,
            albumRatio: album.ratio,
            photoOrientation: leadingMoment.photoOrientation
        )
    }
}
