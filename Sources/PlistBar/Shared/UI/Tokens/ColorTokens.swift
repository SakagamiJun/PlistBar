import AppKit
import SwiftUI

/// Semantic design colors matching cat-bar / Apple HIG guidelines.
/// All colors are backed by system NSColor with opacity tokens — zero hardcoded hex.
enum ColorTokens {
    // MARK: - Labels

    static func primaryLabel(isDark: Bool) -> Color {
        Color(nsColor: .labelColor)
    }

    static func secondaryLabel(isDark: Bool) -> Color {
        Color(nsColor: .labelColor).opacity(
            isDark ? LayoutTokens.Theme.Dark.labelSecondary : LayoutTokens.Theme.Light.labelSecondary
        )
    }

    static func tertiaryLabel(isDark: Bool) -> Color {
        Color(nsColor: .labelColor).opacity(
            isDark ? LayoutTokens.Theme.Dark.labelTertiary : LayoutTokens.Theme.Light.labelTertiary
        )
    }

    // MARK: - Separators & Borders

    static func separator(isDark: Bool) -> Color {
        Color(nsColor: .separatorColor).opacity(
            isDark ? LayoutTokens.Theme.Dark.separator : LayoutTokens.Theme.Light.separator
        )
    }

    static func borderEmphasis(isDark: Bool) -> Color {
        Color(nsColor: .separatorColor).opacity(
            isDark ? LayoutTokens.Theme.Dark.borderEmphasis : LayoutTokens.Theme.Light.borderEmphasis
        )
    }

    // MARK: - Status Colors

    static var positive: Color {
        Color(nsColor: .systemGreen)
    }

    static var warning: Color {
        Color(nsColor: .systemOrange)
    }

    static var critical: Color {
        Color(nsColor: .systemRed)
    }

    static var info: Color {
        Color(nsColor: .systemBlue)
    }

    static var accent: Color {
        Color(nsColor: .controlAccentColor)
    }

    // MARK: - Interaction & Surface

    static func hoverFill(isDark: Bool) -> Color {
        Color(nsColor: .selectedContentBackgroundColor).opacity(
            isDark ? LayoutTokens.Theme.Dark.hoverFill : LayoutTokens.Theme.Light.hoverFill
        )
    }

    static func controlFill(isDark: Bool) -> Color {
        Color(nsColor: .controlColor).opacity(
            isDark ? LayoutTokens.Theme.Dark.controlFill : LayoutTokens.Theme.Light.controlFill
        )
    }

    static func controlBorder(isDark: Bool) -> Color {
        Color(nsColor: .separatorColor).opacity(
            isDark ? LayoutTokens.Theme.Dark.controlBorder : LayoutTokens.Theme.Light.controlBorder
        )
    }
}

extension Color {
    static var nativePositive: Color { ColorTokens.positive }
    static var nativeWarning: Color { ColorTokens.warning }
    static var nativeCritical: Color { ColorTokens.critical }
    static var nativeInfo: Color { ColorTokens.info }
    static var nativeAccent: Color { ColorTokens.accent }
}
