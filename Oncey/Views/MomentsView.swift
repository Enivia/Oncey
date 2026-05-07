import SwiftUI
import SwiftData

struct MomentsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [
        SortDescriptor(\Moment.createdAt, order: .reverse),
        SortDescriptor(\Moment.updatedAt, order: .reverse)
    ]) private var moments: [Moment]

    @State private var pendingTimelineInput: TimelineNavigationInput?
    @State private var pendingShareInput: TimelinePendingShareInput?
    @State private var pendingDeleteMoment: Moment?
    @State private var layoutMode: MomentsLayoutMode = .waterfall
    @State private var currentYear: Int?
    @State private var pendingYearScrollRequest: MomentsYearScrollRequest?
    @State private var errorMessage: String?
    @State private var isPresentingError = false

    private let viewModel = MomentsViewModel()
    private static let scrollCoordinateSpaceName = "MomentsViewScroll"

    var body: some View {
        let sections = viewModel.sections(from: moments)
        let availableYears = viewModel.availableYears(from: moments)

        ZStack {
            AppPageBackground()

            Group {
                if moments.isEmpty {
                    ContentUnavailableView(
                        "No moments yet",
                        systemImage: "clock.badge.questionmark",
                        description: Text("Moments from every album will appear here once you create them.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    GeometryReader { proxy in
                        let horizontalPadding = AppTheme.Spacing.s6
                        let columnSpacing = AppTheme.Spacing.s2
                        let itemSpacing = AppTheme.Spacing.s2
                        let contentWidth = max(proxy.size.width - horizontalPadding * 2, 0)
                        let itemWidth = max((contentWidth - columnSpacing) / 2, 0)
                        let waterfallSections = viewModel.waterfallSections(
                            from: moments,
                            itemWidth: itemWidth,
                            itemSpacing: itemSpacing
                        )
                        let galleryColumns = Array(
                            repeating: GridItem(.flexible(), spacing: itemSpacing, alignment: .top),
                            count: resolvedGalleryColumnCount(
                                for: contentWidth,
                                itemSpacing: itemSpacing
                            )
                        )

                        ScrollViewReader { scrollProxy in
                            ScrollView {
                                LazyVStack(alignment: .leading, spacing: AppTheme.Spacing.s7) {
                                    if layoutMode == .waterfall {
                                        ForEach(waterfallSections) { section in
                                            VStack(alignment: .leading, spacing: AppTheme.Spacing.s4) {
                                                yearTitle(section.title)

                                                HStack(alignment: .top, spacing: columnSpacing) {
                                                    ForEach(section.columns) { column in
                                                        LazyVStack(spacing: itemSpacing) {
                                                            ForEach(column.moments) { moment in
                                                                momentTile(for: moment)
                                                            }
                                                        }
                                                        .frame(maxWidth: .infinity, alignment: .top)
                                                    }
                                                }
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .id(section.year)
                                            .background(sectionOffsetReader(for: section.year))
                                        }
                                    } else {
                                        ForEach(sections) { section in
                                            VStack(alignment: .leading, spacing: AppTheme.Spacing.s4) {
                                                yearTitle(section.title)

                                                LazyVGrid(columns: galleryColumns, alignment: .leading, spacing: itemSpacing) {
                                                    ForEach(section.moments) { moment in
                                                        galleryTile(for: moment)
                                                    }
                                                }
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .id(section.year)
                                            .background(sectionOffsetReader(for: section.year))
                                        }
                                    }
                                }
                                .id(layoutMode.contentIdentity)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, horizontalPadding)
                                .padding(.vertical, AppTheme.Spacing.s6)
                            }
                            .coordinateSpace(name: Self.scrollCoordinateSpaceName)
                            .onAppear {
                                syncCurrentYear(with: availableYears)
                            }
                            .onChange(of: moments.map(\.id)) { _, _ in
                                syncCurrentYear(with: availableYears)
                            }
                            .onChange(of: pendingYearScrollRequest) { _, request in
                                guard let request else {
                                    return
                                }

                                withAnimation {
                                    scrollProxy.scrollTo(request.year, anchor: .top)
                                }
                            }
                            .onPreferenceChange(MomentsYearSectionOffsetPreferenceKey.self) { offsets in
                                syncCurrentYear(with: offsets, fallbackYears: availableYears)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !moments.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        toggleLayoutMode()
                    } label: {
                        Image(systemName: layoutMode.systemImageName)
                    }
                    .accessibilityLabel(layoutMode.toggleAccessibilityLabel)
                }

                MomentYearPickerToolbarContent(
                    availableYears: availableYears,
                    currentYear: currentYear,
                    onSelect: selectYear
                )

                ToolbarSpacer(placement: .bottomBar)
            }
        }
        .navigationDestination(item: $pendingTimelineInput) { input in
            if let album = resolvedAlbum(for: input) {
                AlbumMomentsView(
                    album: album,
                    preferredCurrentMomentID: input.momentID
                )
            } else {
                ContentUnavailableView(
                    "Album unavailable",
                    systemImage: "photo.on.rectangle.angled",
                    description: Text("This moment's album could not be found.")
                )
            }
        }
        .fullScreenCover(item: $pendingShareInput) { input in
            NavigationStack {
                MomentShareView(moment: input.moment)
            }
        }
        .alert("Delete this moment?", isPresented: isPresentingDeleteAlert) {
            Button("Delete", role: .destructive) {
                guard let pendingDeleteMoment else {
                    return
                }

                deleteMoment(pendingDeleteMoment)
                self.pendingDeleteMoment = nil
            }

            Button("Cancel", role: .cancel) {
                pendingDeleteMoment = nil
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .alert("Couldn't delete moment", isPresented: $isPresentingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
    }

    private func momentTile(for moment: Moment) -> some View {
        Group {
            if let album = moment.album {
                Button {
                    pendingTimelineInput = TimelineNavigationInput(
                        albumID: album.id,
                        momentID: moment.id
                    )
                } label: {
                    momentTileContent(for: moment)
                }
                .buttonStyle(.plain)
            } else {
                momentTileContent(for: moment)
            }
        }
    }

    private func galleryTile(for moment: Moment) -> some View {
        Group {
            if let album = moment.album {
                Button {
                    pendingTimelineInput = TimelineNavigationInput(
                        albumID: album.id,
                        momentID: moment.id
                    )
                } label: {
                    MomentGalleryTileView(moment: moment)
                        .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.plain)
            } else {
                MomentGalleryTileView(moment: moment)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func momentTileContent(for moment: Moment) -> some View {
        MomentWaterfallTileView(
            moment: moment,
            monthDayText: viewModel.monthDayText(for: moment),
            albumNameText: viewModel.albumNameText(for: moment),
            onShare: {
                pendingShareInput = TimelinePendingShareInput(moment: moment)
            },
            onDelete: {
                pendingDeleteMoment = moment
            }
        )
    }

    private var isPresentingDeleteAlert: Binding<Bool> {
        Binding(
            get: { pendingDeleteMoment != nil },
            set: { isPresented in
                if !isPresented {
                    pendingDeleteMoment = nil
                }
            }
        )
    }

    private func deleteMoment(_ moment: Moment) {
        do {
            try MomentDeletionService.delete([moment], in: modelContext)
        } catch {
            errorMessage = error.localizedDescription
            isPresentingError = true
        }
    }

    private func yearTitle(_ title: String) -> some View {
        Text(title)
            .font(.title3.weight(.semibold))
            .foregroundStyle(AppTheme.Colors.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sectionOffsetReader(for year: Int) -> some View {
        GeometryReader { geometry in
            Color.clear.preference(
                key: MomentsYearSectionOffsetPreferenceKey.self,
                value: [
                    year: geometry.frame(in: .named(Self.scrollCoordinateSpaceName)).minY
                ]
            )
        }
    }

    private func syncCurrentYear(with availableYears: [Int]) {
        guard let firstYear = availableYears.first else {
            currentYear = nil
            return
        }

        guard let currentYear,
              availableYears.contains(currentYear) else {
            self.currentYear = firstYear
            return
        }

        self.currentYear = currentYear
    }

    private func syncCurrentYear(with offsets: [Int: CGFloat], fallbackYears: [Int]) {
        if let resolvedYear = MomentsYearSelectionResolver.currentYear(sectionMinYByYear: offsets) {
            currentYear = resolvedYear
        } else {
            syncCurrentYear(with: fallbackYears)
        }
    }

    private func selectYear(_ year: Int) {
        currentYear = year
        requestScroll(to: year)
    }

    private func toggleLayoutMode() {
        layoutMode.toggle()
        requestScroll(to: currentYear)
    }

    private func requestScroll(to year: Int?) {
        guard let year else {
            return
        }

        pendingYearScrollRequest = MomentsYearScrollRequest(year: year)
    }

    private func resolvedGalleryColumnCount(for contentWidth: CGFloat, itemSpacing: CGFloat) -> Int {
        let minItemWidth: CGFloat = 72
        let resolvedWidth = max(contentWidth, minItemWidth)
        let rawCount = Int((resolvedWidth + itemSpacing) / (minItemWidth + itemSpacing))
        return max(1, min(4, rawCount))
    }

    private func resolvedAlbum(for input: TimelineNavigationInput) -> Album? {
        moments.first(where: { $0.id == input.momentID })?.album
            ?? moments.first(where: { $0.albumId == input.albumID })?.album
    }
}

private struct TimelinePendingShareInput: Identifiable {
    let id = UUID()
    let moment: Moment
}

private struct TimelineNavigationInput: Identifiable, Hashable {
    let albumID: UUID
    let momentID: UUID

    var id: UUID {
        momentID
    }
}

private struct MomentsYearScrollRequest: Equatable {
    let id = UUID()
    let year: Int
}

private enum MomentsLayoutMode {
    case waterfall
    case gallery

    var contentIdentity: String {
        switch self {
        case .waterfall:
            "waterfall"
        case .gallery:
            "gallery"
        }
    }

    var systemImageName: String {
        switch self {
        case .waterfall:
            "square.grid.2x2"
        case .gallery:
            "photo"
        }
    }

    var toggleAccessibilityLabel: String {
        switch self {
        case .waterfall:
            "Switch to gallery layout"
        case .gallery:
            "Switch to card waterfall layout"
        }
    }

    mutating func toggle() {
        switch self {
        case .waterfall:
            self = .gallery
        case .gallery:
            self = .waterfall
        }
    }
}

private struct MomentsYearSectionOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: [Int: CGFloat] = [:]

    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Album.self, Moment.self, configurations: config)

    let springAlbum = Album(name: "Spring Walk")
    let tripAlbum = Album(name: "Kyoto Trip")
    container.mainContext.insert(springAlbum)
    container.mainContext.insert(tripAlbum)

    container.mainContext.insert(Moment(
        album: springAlbum,
        photo: "",
        note: "First warm breeze of the year.",
        createdAt: Date(timeIntervalSince1970: 1_746_057_600)
    ))
    container.mainContext.insert(Moment(
        album: tripAlbum,
        photo: "",
        note: "",
        createdAt: Date(timeIntervalSince1970: 1_713_715_200)
    ))
    container.mainContext.insert(Moment(
        album: tripAlbum,
        photo: "",
        note: "Lanterns glowing after sunset.",
        createdAt: Date(timeIntervalSince1970: 1_702_166_400)
    ))

    return NavigationStack {
        MomentsView()
    }
    .modelContainer(container)
}
