import SwiftUI

struct ServiceRowView: View {
    let service: LaunchService
    let isSelected: Bool
    let onSelect: () -> Void
    let onStart: () -> Void
    let onStop: () -> Void

    var body: some View {
        HStack(spacing: LayoutTokens.space4) {
            // Status indicator
            statusDot

            // Label
            VStack(alignment: .leading, spacing: 1) {
                Text(service.label)
                    .font(.appBody)
                    .lineLimit(1)
                    .minimumScaleFactor(LayoutTokens.minimumScale)

                HStack(spacing: LayoutTokens.space4) {
                    Text(service.kind.displayName)
                        .font(.appCaption)
                        .foregroundStyle(.tertiary)

                    if let pid = service.pid {
                        Text("PID \(pid)")
                            .font(.appCaption)
                            .foregroundStyle(.tertiary)
                    }

                    if !service.enabled {
                        Text("disabled")
                            .font(.appCaption)
                            .foregroundStyle(.orange)
                    }
                }
            }

            Spacer()

            // Action button
            actionButton
        }
        .menuRowPadding()
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }

    // MARK: - Status dot

    private var statusDot: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 8, height: 8)
            .accessibilityLabel(service.runtimeStatus.rawValue)
    }

    private var statusColor: Color {
        switch service.runtimeStatus {
        case .running:
            return .green
        case .loaded:
            return .orange
        case .stopped:
            return .secondary
        }
    }

    // MARK: - Action button

    @ViewBuilder
    private var actionButton: some View {
        switch service.runtimeStatus {
        case .running:
            Button(action: onStop) {
                Image(systemName: "stop.fill")
                    .font(.appCaption)
            }
            .buttonStyle(.plain)
            .help("Stop service")

        case .loaded, .stopped:
            Button(action: onStart) {
                Image(systemName: "play.fill")
                    .font(.appCaption)
            }
            .buttonStyle(.plain)
            .help("Start service")
        }
    }
}
