import SwiftUI
import UIKit

/// Rentbutik design tokens, shared with the main app.
///
/// Source of truth: `Rentbutik/Design/Theme.swift` in Emin-dev/figma and the
/// "Rentbutik · Tokens" collection in the Figma file Ereat5qYENeSKTvW473gn5.
/// Same names, same values. Change both sides together.
///
/// Colours are defined in code (light/dark via trait collection) so the package
/// needs no colour assets.
public enum Theme {

    // MARK: - Colour

    /// Primary text. Light #1C1C1E, Dark #FFFFFF.
    public static let ink = Color(light: 0x1C1C1E, dark: 0xFFFFFF)
    /// Secondary text. Light #8E8E93, Dark #EBEBF0 at 60 %.
    public static let inkSoft = Color(light: 0x8E8E93, dark: 0xEBEBF0, darkOpacity: 0.6)
    /// Disabled, chevrons, placeholder icons.
    public static let inkFaint = Color(hex: 0xC7C7CC)
    /// The only gold permitted as text. Light #B4640A, Dark #F5A524.
    public static let goldText = Color(light: 0xB4640A, dark: 0xF5A524)
    /// Errors and destructive actions. Light #C0392B, Dark #E06356.
    public static let danger = Color(light: 0xC0392B, dark: 0xE06356)
    /// Positive states (live, finished, paid). Apple system green.
    public static let success = Color(light: 0x248A3D, dark: 0x30D158)
    /// Opaque card. Light #FFFFFF, Dark #1C1C1E.
    public static let card = Color(light: 0xFFFFFF, dark: 0x1C1C1E)
    /// Rows and controls inside cards. Light #F2F2F7, Dark #2C2C2E.
    public static let control = Color(light: 0xF2F2F7, dark: 0x2C2C2E)
    /// Screen background. Light #F2F2F7, Dark #000000.
    public static let background = Color(light: 0xF2F2F7, dark: 0x000000)
    /// Dividers. Light black 6 %, Dark white 14 %.
    public static let hairline = Color(light: 0x000000, lightOpacity: 0.06, dark: 0xFFFFFF, darkOpacity: 0.14)

    // Brand, identical in both modes.
    public static let brandSolid = Color(hex: 0xE0871F)
    public static let accentAmber = Color(hex: 0xF5A524)
    public static let accentHoney = Color(hex: 0xCE9A34)
    public static let accentBronze = Color(hex: 0xB07C16)
    /// Soft cream behind amber glyphs. Dark: amber at 18 %.
    public static let brandTint = Color(light: 0xFFF3E0, dark: 0xF5A524, darkOpacity: 0.18)

    /// Fixed dark ink for content on any gold fill, in both modes.
    /// White on gold measures about 2:1 and must never ship.
    public static let onGold = Color(hex: 0x14161A)

    /// The gold gradient carried by every primary button.
    public static let goldGradient = LinearGradient(
        colors: [Color(hex: 0xFFC24B), Color(hex: 0xF5A524), Color(hex: 0xE0871F)],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    // MARK: - Geometry

    public enum Radius {
        public static let card: CGFloat = 30
        public static let tile: CGFloat = 26
        public static let group: CGFloat = 22
        public static let chip: CGFloat = 18
    }

    public enum Space {
        public static let gap: CGFloat = 14
        public static let screen: CGFloat = 18
        public static let tabBarClearance: CGFloat = 96
    }

    public enum Size {
        /// One button height app-wide. Shorten the copy, never grow the button.
        public static let button: CGFloat = 50
        public static let iconButton: CGFloat = 44
        public static let actionCapsule: CGFloat = 38
        public static let statusDot: CGFloat = 7
        /// The bento unit.
        public static let tileHeight: CGFloat = 172
        public static let badge: CGFloat = 56
        public static let smallBadge: CGFloat = 36
    }

    // MARK: - Motion

    /// Map camera moves, list repopulation, programmatic scroll-to.
    public static let smooth = Animation.smooth(duration: 0.45)
    /// The default. Expand/collapse, selection, chips, sheet content changes.
    public static let snappy = Animation.snappy(duration: 0.32, extraBounce: 0.02)
    /// Success beats and snap-backs.
    public static let bouncy = Animation.spring(response: 0.5, dampingFraction: 0.82)

    // MARK: - Type (SF Pro)

    public enum Font {
        public static let largeTitle = SwiftUI.Font.system(size: 34, weight: .bold)
        public static let title2 = SwiftUI.Font.system(size: 22, weight: .bold)
        public static let title3 = SwiftUI.Font.system(size: 20, weight: .bold)
        public static let headline = SwiftUI.Font.system(size: 17, weight: .semibold)
        public static let body = SwiftUI.Font.system(size: 17, weight: .regular)
        public static let subheadline = SwiftUI.Font.system(size: 15, weight: .medium)
        public static let footnote = SwiftUI.Font.system(size: 13, weight: .semibold)
        public static let caption = SwiftUI.Font.system(size: 12, weight: .regular)
        public static let caption2 = SwiftUI.Font.system(size: 11, weight: .semibold)
        /// SF Pro Rounded for hero numbers.
        public static let heroNumber = SwiftUI.Font.system(size: 40, weight: .bold, design: .rounded)
        public static let tileNumber = SwiftUI.Font.system(size: 28, weight: .bold, design: .rounded)
        public static let rowNumber = SwiftUI.Font.system(size: 17, weight: .semibold, design: .rounded)
    }
}

extension Color {
    public init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }

    /// A colour that follows light and dark mode.
    public init(light: UInt32, lightOpacity: Double = 1, dark: UInt32, darkOpacity: Double = 1) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: dark, alpha: darkOpacity)
                : UIColor(hex: light, alpha: lightOpacity)
        })
    }
}

extension UIColor {
    convenience init(hex: UInt32, alpha: Double) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: alpha)
    }
}
