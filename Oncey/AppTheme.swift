import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum AppTheme {
    enum Colors {
        static let accent = Color(rgbHex: 0x79C6CE)
        static let surface = Color.white
        static let border = Color(rgbHex: 0xF1F3F5)
        static let shadow = Color(argbHex: 0x0D2C3437)
        static let shadowEmphasis = Color(argbHex: 0x1A2C3437)
        static let textPrimary = Color(rgbHex: 0x191919)
        static let textSecondary = Color(rgbHex: 0x4D4F52)
        static let background = Color(rgbHex: 0xF5F7FB)
        static let backgroundDot = Color(argbHex: 0x55B2E2E6)
        static let accentSoft = accent.opacity(0.16)
        static let accentStroke = accent.opacity(0.8)
        static let divider = textSecondary.opacity(0.18)
    }

    enum Spacing {
        static let s1: CGFloat = 4
        static let s2: CGFloat = 8
        static let s3: CGFloat = 12
        static let s4: CGFloat = 14
        static let s5: CGFloat = 16
        static let s6: CGFloat = 20
        static let s7: CGFloat = 24
        static let s8: CGFloat = 28
        static let s9: CGFloat = 32
        static let s10: CGFloat = 36
        static let s11: CGFloat = 40
        static let s12: CGFloat = 48
    }

    enum CornerRadius {
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 32
    }

    enum Shadow {
        static let softRadius: CGFloat = 16
        static let softYOffset: CGFloat = 8
        static let cardRadius: CGFloat = 24
        static let cardYOffset: CGFloat = 10
        static let emphasizedRadius: CGFloat = 12
        static let emphasizedYOffset: CGFloat = 6
        static let floatingRadius: CGFloat = 12
        static let floatingYOffset: CGFloat = 6
    }

    enum BackgroundDots {
        static let diameter: CGFloat = 3
        static let step: CGFloat = Spacing.s6
        static let horizontalInset: CGFloat = Spacing.s2
        static let verticalInset: CGFloat = Spacing.s2
    }

    enum Layout {
        static let albumCardWidthRatio: CGFloat = 0.6
        static let timelinePhotoMaxWidthRatio: CGFloat = 0.7

        static var screenWidth: CGFloat {
#if canImport(UIKit)
            UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .map { $0.screen.bounds.width }
            .first ?? 800
#elseif canImport(AppKit)
            NSScreen.main?.frame.width ?? 800
#else
            800
#endif
        }

        static func fittedSize(for sourceSize: CGSize, maxDimension: CGFloat) -> CGSize {
            fittedSize(for: sourceSize, maxSize: CGSize(width: maxDimension, height: maxDimension))
        }

        static func fittedSize(for sourceSize: CGSize, maxSize: CGSize) -> CGSize {
            guard sourceSize.width > 0, sourceSize.height > 0 else {
                return maxSize
            }

            let widthScale = maxSize.width / sourceSize.width
            let heightScale = maxSize.height / sourceSize.height
            let scale = min(widthScale, heightScale)

            return CGSize(
                width: sourceSize.width * scale,
                height: sourceSize.height * scale
            )
        }
    }
}

enum AppPageBackgroundStyle {
    case plain
    case dotted
}

struct AppPageBackground: View {
    let style: AppPageBackgroundStyle

    init(style: AppPageBackgroundStyle = .plain) {
        self.style = style
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.background

            if style == .dotted {
                DottedBackgroundOverlay()
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

extension View {
    func appPageBackground(_ style: AppPageBackgroundStyle = .plain) -> some View {
        background {
            AppPageBackground(style: style)
        }
    }
}

private struct DottedBackgroundOverlay: View {
    var body: some View {
        Canvas(rendersAsynchronously: true) { context, size in
            let diameter = AppTheme.BackgroundDots.diameter
            let step = AppTheme.BackgroundDots.step
            let horizontalInset = AppTheme.BackgroundDots.horizontalInset
            let verticalInset = AppTheme.BackgroundDots.verticalInset
            let columnCount = Int(ceil(max(0, size.width - horizontalInset * 2) / step)) + 2
            let rowCount = Int(ceil(max(0, size.height - verticalInset * 2) / step)) + 2
            let dotRect = CGRect(origin: .zero, size: CGSize(width: diameter, height: diameter))

            for row in 0..<rowCount {
                for column in 0..<columnCount {
                    let x = horizontalInset + CGFloat(column) * step
                    let y = verticalInset + CGFloat(row) * step
                    let dotPath = Path(ellipseIn: dotRect.offsetBy(dx: x, dy: y))
                    context.fill(dotPath, with: .color(AppTheme.Colors.backgroundDot))
                }
            }
        }
    }
}

private extension Color {
    init(rgbHex: UInt32) {
        self.init(
            .sRGB,
            red: Double((rgbHex >> 16) & 0xFF) / 255,
            green: Double((rgbHex >> 8) & 0xFF) / 255,
            blue: Double(rgbHex & 0xFF) / 255,
            opacity: 1
        )
    }

    init(argbHex: UInt32) {
        self.init(
            .sRGB,
            red: Double((argbHex >> 16) & 0xFF) / 255,
            green: Double((argbHex >> 8) & 0xFF) / 255,
            blue: Double(argbHex & 0xFF) / 255,
            opacity: Double((argbHex >> 24) & 0xFF) / 255
        )
    }
}
