import SwiftUI

enum AppMaterialStyle {
    case flat

    static var current: Self {
        .flat
    }
}

enum AppSurfaceFallbackStyle {
    case material(Material)
    case color(Color)
}

struct AppMaterialSurface: View {
    let cornerRadius: CGFloat
    let fallbackStyle: AppSurfaceFallbackStyle
    let stroke: Color
    var lineWidth: CGFloat = LayoutTokens.stroke

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: self.cornerRadius, style: .continuous)

        self.legacySurface(shape: shape)
            .overlay {
                shape.stroke(self.stroke, lineWidth: self.lineWidth)
            }
    }

    @ViewBuilder
    private func legacySurface(shape: RoundedRectangle) -> some View {
        switch self.fallbackStyle {
        case let .material(material):
            shape.fill(material)
        case let .color(color):
            shape.fill(color)
        }
    }
}

extension AppMaterialSurface {
    /// Convenience for the standard panel surface using `.regularMaterial`.
    static func regularPanel(cornerRadius: CGFloat = LayoutTokens.panelCornerRadius) -> AppMaterialSurface {
        AppMaterialSurface(
            cornerRadius: cornerRadius,
            fallbackStyle: .material(.regularMaterial),
            stroke: Color(nsColor: .separatorColor).opacity(LayoutTokens.Opacity.tint)
        )
    }
}

extension View {
    @ViewBuilder
    func appBorderedButtonStyle(prominent: Bool = false) -> some View {
        if prominent {
            self.buttonStyle(.borderedProminent)
        } else {
            self.buttonStyle(.bordered)
        }
    }
}
