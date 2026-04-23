import CoreGraphics
import Foundation
import SwiftUI

enum MomentCardRenderMode {
    case full
    case thumbnail
}

enum MomentCardStyle: String, CaseIterable, Identifiable {
    case styledCard1

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .styledCard1:
            return "StyledCard1"
        }
    }
}

struct MomentCardView: View {
    let moment: Moment
    let style: MomentCardStyle
    let renderMode: MomentCardRenderMode

    var body: some View {
        switch style {
        case .styledCard1:
            MomentCard1(moment: moment, renderMode: renderMode)
        }
    }
}

#Preview {
    let album = Album(name: "Tokyo Trip 2024")
    let moment = Moment(
        album: album,
        photo: "",
        location: "Shibuya, Tokyo",
        note: "Golden hour at the famous crossing — the city alive with evening rush.",
        createdAt: Date(timeIntervalSince1970: 1_713_628_800)
    )

    ScrollView {
        VStack(spacing: 24) {
            MomentCardView(moment: moment, style: .styledCard1, renderMode: .full)
                .frame(maxWidth: 360)

            MomentCardView(moment: moment, style: .styledCard1, renderMode: .thumbnail)
                .frame(width: 120)
        }
        .padding()
    }
    .background(AppTheme.Colors.background)
}
