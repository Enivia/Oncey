import CoreGraphics
import Testing
@testable import Oncey

struct MomentCreationLiveOverlayLayoutResolverTests {
    @Test func landscapeOverlayRotatesAndPinsToLeadingEdge() {
        let layout = MomentCreationLiveOverlayLayoutResolver.resolve(
            imageSize: CGSize(width: 1_600, height: 900),
            albumOrientation: nil,
            previewSize: CGSize(width: 200, height: 600)
        )

        #expect(layout != nil)
        #expect(layout?.rotationDegrees == -90)
        #expect(isClose(layout?.frame.minX ?? -1, 0))
        #expect(isClose(layout?.frame.minY ?? -1, 122.2222, tolerance: 0.01))
        #expect(isClose(layout?.frame.width ?? -1, 200, tolerance: 0.01))
        #expect(isClose(layout?.frame.height ?? -1, 355.5555, tolerance: 0.01))
        #expect(isClose(layout?.contentSize.width ?? -1, 355.5555, tolerance: 0.01))
        #expect(isClose(layout?.contentSize.height ?? -1, 200, tolerance: 0.01))
    }

    @Test func portraitOverlayPinsToBottomEdge() {
        let layout = MomentCreationLiveOverlayLayoutResolver.resolve(
            imageSize: CGSize(width: 900, height: 1_200),
            albumOrientation: nil,
            previewSize: CGSize(width: 400, height: 700)
        )

        #expect(layout != nil)
        #expect(layout?.rotationDegrees == 0)
        #expect(isClose(layout?.frame.minX ?? -1, 0))
        #expect(isClose(layout?.frame.minY ?? -1, 166.6667, tolerance: 0.01))
        #expect(isClose(layout?.frame.width ?? -1, 400, tolerance: 0.01))
        #expect(isClose(layout?.frame.height ?? -1, 533.3333, tolerance: 0.01))
        #expect(isClose(layout?.contentSize.width ?? -1, 400, tolerance: 0.01))
        #expect(isClose(layout?.contentSize.height ?? -1, 533.3333, tolerance: 0.01))
    }

    private func isClose(_ lhs: CGFloat, _ rhs: CGFloat, tolerance: CGFloat = 0.001) -> Bool {
        abs(lhs - rhs) <= tolerance
    }
}