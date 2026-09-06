import AppKit
import SwiftUI

struct ServiceDetailView: View {
    @Environment(\.colorScheme) private var colorScheme
    let service: LaunchService
    @Bindable var viewModel: ServiceListViewModel
    @Bindable var logViewModel: LogViewerViewModel
    @Bindable var alertViewModel: AlertViewModel
    let onBack: () -> Void
    let onEdit: () -> Void

    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        VStack(spacing: 0) {
            // Service info header with Back button
            serviceHeader

            Divider()

            // Action bar
            actionBar

            Divider()

            // Content: log viewer
            LogViewerView(viewModel: logViewModel, service: service)
        }
        .onAppear {
            logViewModel.loadLogs(for: service)
        }
    }

    // MARK: - Service header

    private var serviceHeader: some View {
        VStack(alignment: .leading, spacing: LayoutTokens.space6) {
            HStack(spacing: LayoutTokens.space4) {
                Button(action: onBack) {
                    HStack(spacing: 2) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.appCaption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(ColorTokens.accent)

                Spacer()

                Button {
                    NSWorkspace.shared.activateFileViewerSelecting([service.plistURL])
                } label: {
                    Image(systemName: "folder")
                        .font(.appCaption)
                }
                .buttonStyle(.plain)
                .help("Reveal plist in Finder")

                if service.scope.isUserWritable {
                    Button("Edit Plist") { onEdit() }
                        .font(.appCaption)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                } else {
                    Text("Read-Only")
                        .font(.system(size: 9, weight: .semibold))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(ColorTokens.controlFill(isDark: isDark)))
                        .foregroundStyle(ColorTokens.tertiaryLabel(isDark: isDark))
                        .help("Global services are system-protected.")
                }
            }

            // Title & Status
            HStack(spacing: LayoutTokens.space6) {
                StatusDot(status: service.runtimeStatus, size: 10)

                Text(service.label)
                    .font(.appSubhead)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .foregroundStyle(ColorTokens.primaryLabel(isDark: isDark))
            }

            // Info Badges Row
            HStack(spacing: LayoutTokens.space8) {
                infoBadge("Scope", service.scope.rawValue)
                infoBadge("Status", service.runtimeStatus.rawValue)
                if let pid = service.pid {
                    infoBadge("PID", "\(pid)")
                }
                infoBadge("Enabled", service.enabled ? "Yes" : "No")
                infoBadge("RunAtLoad", service.runAtLoad ? "Yes" : "No")
                infoBadge("KeepAlive", service.keepAlive ? "Yes" : "No")
            }
        }
        .menuRowPadding()
    }

    // MARK: - Action bar

    private var actionBar: some View {
        HStack(spacing: LayoutTokens.space4) {
            switch service.runtimeStatus {
            case .running:
                ConfirmButton(
                    title: "Stop",
                    message: "Stop \(service.label)?",
                    destructive: true
                ) {
                    viewModel.runAction(LaunchctlService.stop, label: "Stopping")
                }

            case .loaded, .stopped:
                Button("Start") {
                    viewModel.runAction(LaunchctlService.start, label: "Starting")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            if service.enabled {
                Button("Disable") {
                    viewModel.runAction(LaunchctlService.disable, label: "Disabling")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            } else {
                Button("Enable") {
                    viewModel.runAction(LaunchctlService.enable, label: "Enabling")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            Button("Load") {
                viewModel.runAction(LaunchctlService.load, label: "Loading")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Button("Unload") {
                viewModel.runAction(LaunchctlService.unload, label: "Unloading")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            if service.scope.isUserWritable {
                ConfirmButton(
                    title: "Delete",
                    message: "Permanently delete plist for \(service.label)?",
                    destructive: true
                ) {
                    viewModel.runAction(LaunchctlService.deleteUserAgent, label: "Deleting")
                    onBack()
                }
            }

            Spacer()
        }
        .menuRowPadding(vertical: LayoutTokens.space4)
    }

    // MARK: - Helpers

    private func infoBadge(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(ColorTokens.tertiaryLabel(isDark: isDark))
            Text(value)
                .font(.appCaption)
                .fontWeight(.medium)
                .lineLimit(1)
                .foregroundStyle(ColorTokens.secondaryLabel(isDark: isDark))
        }
    }
}
