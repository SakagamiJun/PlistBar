import SwiftUI

struct StatusDot: View {
    let status: LaunchRuntimeStatus
    var size: CGFloat = 8

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .accessibilityLabel(status.rawValue)
    }

    private var color: Color {
        switch status {
        case .running:
            return .nativePositive
        case .loaded:
            return .nativeWarning
        case .stopped:
            return Color(nsColor: .tertiaryLabelColor)
        }
    }
}
