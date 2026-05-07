import CoreGraphics

struct MomentsYearSelectionResolver {
    static func currentYear(
        sectionMinYByYear: [Int: CGFloat],
        topThreshold: CGFloat = 0
    ) -> Int? {
        if let currentSection = sectionMinYByYear
            .filter({ $0.value <= topThreshold })
            .max(by: { lhs, rhs in
                if lhs.value == rhs.value {
                    return lhs.key < rhs.key
                }

                return lhs.value < rhs.value
            }) {
            return currentSection.key
        }

        return sectionMinYByYear.min(by: { lhs, rhs in
            if lhs.value == rhs.value {
                return lhs.key > rhs.key
            }

            return lhs.value < rhs.value
        })?.key
    }
}