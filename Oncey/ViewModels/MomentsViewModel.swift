import Foundation

struct MomentsViewModel {
    struct Section: Identifiable {
        let year: Int
        let title: String
        var moments: [Moment]

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

    func monthDayText(for moment: Moment, formatter: DateFormatter = Self.monthDayFormatter) -> String {
        formatter.string(from: moment.createdAt)
    }

    func albumNameText(for moment: Moment) -> String {
        let name = moment.album?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? "Unknown Album" : name
    }
}
