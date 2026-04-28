import SwiftUI
#if canImport(SwiftData)
import SwiftData
#endif
#if canImport(UIKit)
import UIKit
#endif

struct MomentsTimelineView: View {
    @Environment(\.modelContext) private var modelContext

    let album: Album
    @State private var isCreationPresented = false
    @State private var pendingShareInput: TimelinePendingShareInput?
    @State private var pendingSingleDeleteMoment: Moment?
    @State private var settledIndex = 0
    @State private var focusPosition: CGFloat = 0
    @State private var errorTitle = "Couldn't load photo"
    @State private var errorMessage: String?
    @State private var isPresentingError = false

    private var viewModel: MomentsTimelineViewModel {
        MomentsTimelineViewModel(album: album)
    }

    var body: some View {
        ZStack {
            AppPageBackground(style: .dotted)

            Group {
                if viewModel.moments.isEmpty {
                    ContentUnavailableView(
                        "No moments yet",
                        systemImage: "clock.badge.plus",
                        description: Text("Add a moment from the toolbar.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    GeometryReader { geometry in
                        let albumAspectRatio = preferredAlbumAspectRatio
                        let metrics = MomentTimelineStageMetrics.resolve(
                            containerSize: geometry.size,
                            albumAspectRatio: albumAspectRatio ?? 3 / 4
                        )

                        VStack {
                            Spacer(minLength: 0)

                            MomentTimelineStageView(
                                moments: viewModel.moments,
                                focusPosition: focusPosition,
                                metrics: metrics,
                                albumAspectRatio: albumAspectRatio,
                                timestampTextProvider: { moment in
                                    viewModel.timestampText(for: moment)
                                },
                                onShare: { moment in
                                    pendingShareInput = TimelinePendingShareInput(moment: moment)
                                },
                                onDelete: { moment in
                                    pendingSingleDeleteMoment = moment
                                }
                            )
                            .frame(maxWidth: .infinity)
                            .highPriorityGesture(
                                dragGesture(
                                    stepDistance: metrics.stepDistance,
                                    momentCount: viewModel.moments.count
                                )
                            )

                            Spacer(minLength: 0)
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                }
            }
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isCreationPresented = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add moment")
            }
        }
        .fullScreenCover(isPresented: $isCreationPresented) {
            NavigationStack {
                MomentCreationView(mode: .newMoment(album: album)) { _ in }
            }
        }
        .fullScreenCover(item: $pendingShareInput) { input in
            NavigationStack {
                MomentShareView(moment: input.moment)
            }
        }
        .alert("Delete this moment?", isPresented: isPresentingSingleDeleteAlert) {
            Button("Delete", role: .destructive) {
                guard let pendingSingleDeleteMoment else {
                    return
                }

                deleteMoments([pendingSingleDeleteMoment])
                self.pendingSingleDeleteMoment = nil
            }

            Button("Cancel", role: .cancel) {
                pendingSingleDeleteMoment = nil
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .alert(errorTitle, isPresented: $isPresentingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
        .onChange(of: viewModel.moments.count) { oldCount, newCount in
            guard newCount > 0 else {
                settledIndex = 0
                focusPosition = 0
                return
            }

            if newCount > oldCount {
                settledIndex = 0
            } else {
                settledIndex = min(settledIndex, newCount - 1)
            }

            focusPosition = CGFloat(settledIndex)
        }
        .onAppear {
            focusPosition = CGFloat(settledIndex)
        }
    }

    private var isPresentingSingleDeleteAlert: Binding<Bool> {
        Binding(
            get: { pendingSingleDeleteMoment != nil },
            set: { isPresented in
                if !isPresented {
                    pendingSingleDeleteMoment = nil
                }
            }
        )
    }

    private var preferredAlbumAspectRatio: CGFloat? {
        if let ratio = album.ratio?.aspectRatio {
            return ratio
        }

        guard let templatePhotoAspectRatio = album.templatePhotoAspectRatio else {
            return nil
        }

        return CGFloat(templatePhotoAspectRatio)
    }

    private func activeFocusedPhotoSize(in moments: [Moment]) -> CGSize? {
        guard !moments.isEmpty else {
            return nil
        }

        let activeIndex = min(max(Int(focusPosition.rounded()), 0), moments.count - 1)
        return ImageResourceService.imageSize(from: moments[activeIndex].photo)
    }

    private func dragGesture(stepDistance: CGFloat, momentCount: Int) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                let dragState = MomentTimelineSceneResolver.dragState(
                    translation: value.translation.height,
                    predictedEndTranslation: value.predictedEndTranslation.height,
                    stepDistance: stepDistance,
                    momentCount: momentCount,
                    currentSettledIndex: settledIndex
                )

                focusPosition = dragState.focusPosition
            }
            .onEnded { value in
                let dragState = MomentTimelineSceneResolver.dragState(
                    translation: value.translation.height,
                    predictedEndTranslation: value.predictedEndTranslation.height,
                    stepDistance: stepDistance,
                    momentCount: momentCount,
                    currentSettledIndex: settledIndex
                )

                settledIndex = dragState.targetIndex

                withAnimation(.snappy(duration: 0.28, extraBounce: 0.08)) {
                    focusPosition = CGFloat(dragState.targetIndex)
                }
            }
    }

    private func deleteMoments(_ moments: [Moment]) {
        guard !moments.isEmpty else {
            return
        }

        do {
            try MomentDeletionService.delete(moments, in: modelContext)

            let remainingCount = viewModel.moments.count
            if remainingCount == 0 {
                settledIndex = 0
                focusPosition = 0
            } else {
                settledIndex = min(settledIndex, remainingCount - 1)
                focusPosition = CGFloat(settledIndex)
            }
        } catch {
            errorTitle = "Couldn't delete moment"
            errorMessage = error.localizedDescription
            isPresentingError = true
        }
    }
}

private struct TimelinePendingShareInput: Identifiable {
    let id = UUID()
    let moment: Moment
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Album.self, Moment.self, configurations: config)

    let album = Album(name: "Tokyo Trip 2024")
    container.mainContext.insert(album)

    let entries: [(TimeInterval, String)] = [
        (1_713_715_200, "Neon signs everywhere — the city never sleeps. Neon signs everywhere — the city never sleeps."),
        (1_713_628_800, "Golden hour at the famous crossing. Golden hour at the famous crossing. Golden hour at the famous crossing."),
        (1_713_542_400, "Colourful street fashion and crepe shops.")
    ]
    for (ts, note) in entries {
        container.mainContext.insert(Moment(
            album: album, photo: "", note: note,
            createdAt: Date(timeIntervalSince1970: ts)
        ))
    }

    return NavigationStack {
        MomentsTimelineView(album: album)
    }
    .modelContainer(container)
}
