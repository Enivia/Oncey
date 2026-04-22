import CoreGraphics
import Foundation
import SwiftUI

enum MomentCardLayout {
    static let fullCardWidth: CGFloat = 360
    static let thumbnailCardWidth: CGFloat = 168
}

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