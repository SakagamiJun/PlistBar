import AppKit
import SwiftUI

struct ServiceRowView: View {
    @Environment(\.colorScheme) private var colorScheme
    let service: LaunchService
    let isSelected: Bool
    let onSelect: () -> Void
    let onStart: () -> Void
    let onStop: () -> Void
    var onToggleEnable: (() -> Void)? = nil
    var onRevealInFinder: (() -> Void)? = nil

    @State private var isHovered = false

    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        HStack(spacing: LayoutTokens.space6) {
            // Status indicator dot
            StatusDot(status: service.runtimeStatus)

            // Label & metadata
            VStack(alignment: .leading, spacing: 2) {
                Text(service.label)
                    .font(.appBody)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .minimumScaleFactor(LayoutTokens.minimumScale)
                    .foregroundStyle(ColorTokens.primaryLabel(isDark: isDark))

                HStack(spacing: LayoutTokens.space4) {
                    Text(service.kind.displayName)
                        .font(.appCaption)
                        .foregroundStyle(ColorTokens.tertiaryLabel(isDark: isDark))

                    if let pid = service.pid {
                        Text("• PID \(pid)")
                            .font(.appCaption)
                            .foregroundStyle(ColorTokens.tertiaryLabel(isDark: isDark))
                    }

                    if !service.enabled {
                        Text("• disabled")
                            .font(.appCaption)
                            .foregroundStyle(ColorTokens.warning)
                    }
                }
            }

            Spacer()

            // Quick play/stop action button
            actionButton

            // Chevron indicating clickable detail
            Image(systemName: "chevron.right")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(ColorTokens.tertiaryLabel(isDark: isDark))
                .opacity(isHovered ? 1.0 : 0.4)
        }
        .menuRowPadding(vertical: LayoutTokens.space6)
        .hoverRowBackground(isHovered: isHovered, isSelected: isSelected)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .onHover { isHovered = $0 }
        .contextMenu {
            if service.runtimeStatus == .running {
                Button {
                    onStop()
                } label: {
                    Label("Stop Service", systemImage: "stop.fill")
                }
            } else {
                Button {
                    onStart()
                } label: {
                    Label("Start Service", systemImage: "play.fill")
                }
            }

            if let onToggleEnable {
                Button {
                    onToggleEnable()
                } label: {
                    Label(
                        service.enabled ? "Disable" : "Enable",
                        systemImage: service.enabled ? "slash.circle" : "checkmark.circle"
                    )
                }
            }

            Divider()

            Button {
                NSWorkspace.shared.activateFileViewerSelecting([service.plistURL])
            } label: {
                Label("Reveal in Finder", systemImage: "folder")
            }

            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(service.label, forType: .string)
            } label: {
                Label("Copy Label", systemImage: "doc.on.doc")
            }

            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(service.plistURL.path, forType: .string)
            } label: {
                Label("Copy Plist Path", systemImage: "link")
            }
        }
    }

    // MARK: - Action button

    @ViewBuilder
    private var actionButton: some View {
        switch service.runtimeStatus {
        case .running:
            Button(action: onStop) {
                Image(systemName: "stop.circle.fill")
                    .font(.appSubhead)
                    .foregroundStyle(ColorTokens.critical.opacity(0.85))
            }
            .buttonStyle(.plain)
            .help("Stop service")

        case .loaded, .stopped:
            Button(action: onStart) {
                Image(systemName: "play.circle.fill")
                    .font(.appSubhead)
                    .foregroundStyle(ColorTokens.positive.opacity(0.85))
            }
            .buttonStyle(.plain)
            .help("Start service")
        }
    }
}
