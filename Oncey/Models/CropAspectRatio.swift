import CoreGraphics

enum CropAspectRatio: String, CaseIterable, Identifiable {
    case square = "1:1"
    case landscape = "4:3"
    case portrait = "3:4"

    var id: Self { self }

    var label: String {
        rawValue
    }

    var dimensions: CGSize {
        switch self {
        case .square:
            return CGSize(width: 1, height: 1)
        case .landscape:
            return CGSize(width: 4, height: 3)
        case .portrait:
            return CGSize(width: 3, height: 4)
        }
    }

    var value: CGFloat {
        dimensions.width / dimensions.height
    }

    func cropSize(in container: CGSize) -> CGSize {
        let horizontalInset: CGFloat = 24
        let verticalInset: CGFloat = 168
        let maxWidth = max(180, container.width - horizontalInset * 2)
        let maxHeight = max(180, container.height - verticalInset * 2)

        var width = maxWidth
        var height = width / value

        if height > maxHeight {
            height = maxHeight
            width = height * value
        }

        return CGSize(width: width, height: height)
    }

    func exportSize(longEdge: CGFloat = 2048) -> CGSize {
        let longestDimension = max(dimensions.width, dimensions.height)
        let scale = longEdge / longestDimension

        return CGSize(
            width: dimensions.width * scale,
            height: dimensions.height * scale
        )
    }
}