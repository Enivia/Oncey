import CoreGraphics
import Foundation
import Testing
@testable import Oncey

struct AlbumOrientationSyncTests {
    @Test func syncOrientationDoesNotUseUpdatedAtAsTieBreaker() {
        let album = Album(name: "Trip")
        let createdAt = Date(timeIntervalSince1970: 1_713_744_000)
        let firstMoment = Moment(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            album: album,
            photo: "first",
            createdAt: createdAt,
            updatedAt: createdAt
        )
        let secondMoment = Moment(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            album: album,
            photo: "second",
            createdAt: createdAt,
            updatedAt: createdAt.addingTimeInterval(-60)
        )

        album.moments = [secondMoment, firstMoment]

        album.syncOrientation { path in
            path == "first"
                ? CGSize(width: 24, height: 32)
                : CGSize(width: 32, height: 24)
        }
        #expect(album.orientation == .portrait)

        firstMoment.updatedAt = createdAt.addingTimeInterval(300)
        album.syncOrientation { path in
            path == "first"
                ? CGSize(width: 24, height: 32)
                : CGSize(width: 32, height: 24)
        }

        #expect(album.orientation == .portrait)
    }
}