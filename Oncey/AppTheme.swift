import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum AppTheme {
    enum Colors {
        static let accent = Color(rgbHex: 0x5B7ACF)
        static let accentSoft = Color(rgbHex: 0x8BA4EB)
        static let accentStroke = Color(rgbHex: 0xDCE6FF)
        
        static let secondary = Color(rgbHex: 0x6A5780)
        static let secondarySoft = Color(rgbHex: 0xE9E2F4)
        
        static let surface = Color.white
        static let border = Color(rgbHex: 0xF1F3F5)
        static let divider = Color(rgbHex: 0xC3CBD0)
        
        static let shadow = Color(argbHex: 0x0D2C3437)
        static let shadowEmphasis = Color(argbHex: 0x1A2C3437)
        
        static let textPrimary = Color(rgbHex: 0x2C3437)
        static let textSecondary = Color(rgbHex: 0x617075)
        
        static let background = Color(rgbHex: 0xF8FAFC)
        static let backgroundDot = accent.opacity(0.1)
        
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
        static let momentsPhotoMaxWidthRatio: CGFloat = 0.7
        static let momentsPageHeightRatio: CGFloat = 0.7
        static let momentsPageHorizontalPadding: CGFloat = Spacing.s6
        static let momentsPageContentSpacing: CGFloat = Spacing.s3
        static let momentsTimestampHeight: CGFloat = 28
        static let momentsNoteHeight: CGFloat = 32
        static let momentsDotSize: CGFloat = 12

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
    case dark
    case light
}

struct AppPageBackground: View {
    let style: AppPageBackgroundStyle

    init(style: AppPageBackgroundStyle = .light) {
        self.style = style
    }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            LinenCanvasView(size: size, style: style)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}


extension View {
    func appPageBackground(_ style: AppPageBackgroundStyle = .light) -> some View {
        background {
            AppPageBackground(style: style)
        }
    }
}

private struct LinenCanvasView: View {
    let size: CGSize
    let style: AppPageBackgroundStyle
    @State private var rendered: UIImage?
    
    var body: some View {
        Group {
            if let rendered {
                Image(uiImage: rendered)
                    .resizable()
                    .ignoresSafeArea()
            } else {
                // 生成前显示底色，避免白屏
                backgroundColor
            }
        }
        .task(id: size) {
            // 只在 size 变化时重新生成（首次 + 横竖屏切换）
            rendered = await renderLinen(size: size)
        }
    }

    private var backgroundColor: Color {
        switch style {
            case .light:  return AppTheme.Colors.background
            case .dark: return AppTheme.Colors.accentSoft
        }
    }

    private func colors() -> (bg: UIColor, light: UIColor, dark: UIColor) {
        switch style {
        case .light:
            return (
                bg:    UIColor(AppTheme.Colors.background),
                light: UIColor(AppTheme.Colors.accentSoft.opacity(0.1)),
                dark:  UIColor(AppTheme.Colors.secondarySoft.opacity(0.1))
            )
        case .dark:
            return (
                bg:    UIColor(AppTheme.Colors.accentSoft),
                light: UIColor.white.withAlphaComponent(0.05),
                dark:  UIColor(AppTheme.Colors.accent.opacity(0.08))
            )
        }
    }

    private func renderLinen(size: CGSize) async -> UIImage {
        let (bgColor, lightColor, darkColor) = colors()

        return await Task.detached(priority: .userInitiated) {
            let renderer = UIGraphicsImageRenderer(size: size)
            return renderer.image { ctx in
                let context = ctx.cgContext

                bgColor.setFill()
                context.fill(CGRect(origin: .zero, size: size))

                var y: CGFloat = 0
                while y < size.height {
                    let color = Int(y / 2) % 2 == 0 ? lightColor : darkColor
                    context.setStrokeColor(color.cgColor)
                    context.setLineWidth(0.8)
                    context.move(to: CGPoint(x: 0, y: y))
                    context.addLine(to: CGPoint(x: size.width, y: y))
                    context.strokePath()
                    y += 2
                }

                var x: CGFloat = 0
                while x < size.width {
                    let color = Int(x / 2) % 2 == 0 ? darkColor : lightColor
                    context.setStrokeColor(color.cgColor)
                    context.setLineWidth(0.6)
                    context.move(to: CGPoint(x: x, y: 0))
                    context.addLine(to: CGPoint(x: x, y: size.height))
                    context.strokePath()
                    x += 2
                }
            }
        }.value
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
