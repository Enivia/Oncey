import CoreGraphics
import Foundation

struct MomentsViewModel {
    struct Section: Identifiable {
        let year: Int
        let title: String
        var moments: [Moment]

        var id: Int { year }
    }

    struct WaterfallColumn: Identifiable {
        let id: Int
        let moments: [Moment]
    }

    struct WaterfallSection: Identifiable {
        let year: Int
        let title: String
        let columns: [WaterfallColumn]

        var id: Int { year }
    }

    private static let monthDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.setLocalizedDateFormatFromTemplate("MMMd")
        return formatter
    }()

    private static let yearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.setLocalizedDateFormatFromTemplate("yyyy")
        return formatter
    }()

    private static let fallbackPhotoSize = CGSize(width: 4, height: 3)
    private static let metadataHeightWithoutNote: CGFloat = 76
    private static let metadataHeightWithNote: CGFloat = 120

    var title: String {
        "Moments"
    }

    func orderedMoments(_ moments: [Moment]) -> [Moment] {
        moments.sorted { lhs, rhs in
            if lhs.createdAt == rhs.createdAt {
                if lhs.updatedAt == rhs.updatedAt {
                    return lhs.id.uuidString > rhs.id.uuidString
                }

                return lhs.updatedAt > rhs.updatedAt
            }

            return lhs.createdAt > rhs.createdAt
        }
    }

    func sections(
        from moments: [Moment],
        calendar: Calendar = .current,
        yearFormatter: DateFormatter = Self.yearFormatter
    ) -> [Section] {
        var sections: [Section] = []

        for moment in orderedMoments(moments) {
            let year = calendar.component(.year, from: moment.createdAt)

            if let lastIndex = sections.indices.last, sections[lastIndex].year == year {
                sections[lastIndex].moments.append(moment)
            } else {
                sections.append(
                    Section(
                        year: year,
                        title: yearFormatter.string(from: moment.createdAt),
                        moments: [moment]
                    )
                )
            }
        }

        return sections
    }

    func waterfallSections(
        from moments: [Moment],
        itemWidth: CGFloat,
        columnCount: Int = 2,
        itemSpacing: CGFloat = 0,
        imageSizeResolver: (Moment) -> CGSize? = Self.defaultImageSize
    ) -> [WaterfallSection] {
        sections(from: moments).map {
            waterfallSection(
                from: $0,
                itemWidth: itemWidth,
                columnCount: columnCount,
                itemSpacing: itemSpacing,
                imageSizeResolver: imageSizeResolver
            )
        }
    }

    func waterfallSection(
        from section: Section,
        itemWidth: CGFloat,
        columnCount: Int = 2,
        itemSpacing: CGFloat = 0,
        imageSizeResolver: (Moment) -> CGSize? = Self.defaultImageSize
    ) -> WaterfallSection {
        let resolvedColumnCount = max(1, columnCount)
        var columnMoments = Array(repeating: [Moment](), count: resolvedColumnCount)
        var columnHeights = Array(repeating: CGFloat.zero, count: resolvedColumnCount)

        for moment in section.moments {
            let estimatedHeight = estimatedTileHeight(
                for: moment,
                itemWidth: itemWidth,
                imageSizeResolver: imageSizeResolver
            )
            let targetColumnIndex = shortestColumnIndex(in: columnHeights)
            let spacingHeight = columnMoments[targetColumnIndex].isEmpty ? CGFloat.zero : itemSpacing

            columnMoments[targetColumnIndex].append(moment)
            columnHeights[targetColumnIndex] += spacingHeight + estimatedHeight
        }

        let columns = columnMoments.enumerated().map { index, moments in
            WaterfallColumn(id: index, moments: moments)
        }

        return WaterfallSection(year: section.year, title: section.title, columns: columns)
    }

    func monthDayText(for moment: Moment, formatter: DateFormatter = Self.monthDayFormatter) -> String {
        formatter.string(from: moment.createdAt)
    }

    func albumNameText(for moment: Moment) -> String {
        let name = moment.album?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? "Unknown Album" : name
    }

    func estimatedTileHeight(
        for moment: Moment,
        itemWidth: CGFloat,
        imageSizeResolver: (Moment) -> CGSize? = Self.defaultImageSize
    ) -> CGFloat {
        estimatedImageHeight(
            for: moment,
            itemWidth: itemWidth,
            imageSizeResolver: imageSizeResolver
        ) + estimatedMetadataHeight(for: moment)
    }

    private func estimatedImageHeight(
        for moment: Moment,
        itemWidth: CGFloat,
        imageSizeResolver: (Moment) -> CGSize?
    ) -> CGFloat {
        let resolvedItemWidth = max(itemWidth, 1)
        let sourceSize = imageSizeResolver(moment) ?? Self.fallbackPhotoSize
        let resolvedSourceSize: CGSize

        if sourceSize.width > 0, sourceSize.height > 0 {
            resolvedSourceSize = sourceSize
        } else {
            resolvedSourceSize = Self.fallbackPhotoSize
        }

        return resolvedItemWidth * (resolvedSourceSize.height / resolvedSourceSize.width)
    }

    private func estimatedMetadataHeight(for moment: Moment) -> CGFloat {
        let trimmedNote = moment.note.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedNote.isEmpty ? Self.metadataHeightWithoutNote : Self.metadataHeightWithNote
    }

    private func shortestColumnIndex(in heights: [CGFloat]) -> Int {
        heights.enumerated().min { lhs, rhs in
            if lhs.element == rhs.element {
                return lhs.offset < rhs.offset
            }

            return lhs.element < rhs.element
        }?.offset ?? 0
    }

    private static func defaultImageSize(_ moment: Moment) -> CGSize? {
        guard !moment.photo.isEmpty else {
            return nil
        }

        return ImageResourceService.imageSize(from: moment.photo)
    }
}
