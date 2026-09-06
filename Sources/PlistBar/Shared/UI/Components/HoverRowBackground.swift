import SwiftUI

struct HoverRowBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    let isHovered: Bool
    var isSelected: Bool = false
    var cornerRadius: CGFloat = LayoutTokens.cornerRadius

    var body: some View {
        let isDark = colorScheme == .dark
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(fillColor(isDark: isDark))
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(ColorTokens.accent.opacity(0.3), lineWidth: LayoutTokens.stroke)
                }
            }
    }

    private func fillColor(isDark: Bool) -> Color {
        if isSelected {
            return ColorTokens.accent.opacity(LayoutTokens.Opacity.tint)
        } else if isHovered {
            return ColorTokens.hoverFill(isDark: isDark)
        } else {
            return .clear
        }
    }
}

extension View {
    func hoverRowBackground(isHovered: Bool, isSelected: Bool = false, cornerRadius: CGFloat = LayoutTokens.cornerRadius) -> some View {
        self.background(
            HoverRowBackground(isHovered: isHovered, isSelected: isSelected, cornerRadius: cornerRadius)
        )
    }
}
