import CoreGraphics

enum MomentPhotoOrientation: String, Codable, Sendable {
    case portrait
    case landscape

    var isLandscape: Bool {
        self == .landscape
    }

    var toggled: Self {
        isLandscape ? .portrait : .landscape
    }

    static func inferred(from size: CGSize) -> Self {
        guard size.width > 0,
              size.height > 0,
              size.width > size.height else {
            return .portrait
        }

        return .landscape
    }
}