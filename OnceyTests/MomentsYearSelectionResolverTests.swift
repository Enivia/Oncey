import CoreGraphics
import Testing
@testable import Oncey

struct MomentsYearSelectionResolverTests {
    @Test func resolvesClosestSectionAtOrAboveTopThreshold() {
        let currentYear = MomentsYearSelectionResolver.currentYear(
            sectionMinYByYear: [
                2026: -240,
                2025: -18,
                2024: 180,
            ]
        )

        #expect(currentYear == 2025)
    }

    @Test func fallsBackToFirstSectionBelowTopThreshold() {
        let currentYear = MomentsYearSelectionResolver.currentYear(
            sectionMinYByYear: [
                2026: 24,
                2025: 220,
                2024: 460,
            ]
        )

        #expect(currentYear == 2026)
    }
}