import SwiftUI

struct ServiceDetailView: View {
    let service: LaunchService
    @Bindable var viewModel: ServiceListViewModel
    @Bindable var logViewModel: LogViewerViewModel
    @Bindable var alertViewModel: AlertViewModel
    let onEdit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Service info header
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
        VStack(alignment: .leading, spacing: LayoutTokens.space4) {
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)

                Text(service.label)
                    .font(.appSubhead)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                Spacer()

                Button("Edit") { onEdit() }
                    .font(.appCaption)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }

            HStack(spacing: LayoutTokens.space8) {
                infoBadge("Scope", service.scope.rawValue)
                infoBadge("Kind", service.kind.rawValue)
                infoBadge("Status", service.runtimeStatus.rawValue)
                if let pid = service.pid {
                    infoBadge("PID", "\(pid)")
                }
                infoBadge("Enabled", service.enabled ? "Yes" : "No")
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

            if service.scope == .userAgents {
                ConfirmButton(
                    title: "Delete",
                    message: "Permanently delete \(service.label)?",
                    destructive: true
                ) {
                    viewModel.runAction(LaunchctlService.deleteUserAgent, label: "Deleting")
                }
            }

            Spacer()
        }
        .menuRowPadding(vertical: LayoutTokens.space4)
    }

    // MARK: - Helpers

    private var statusColor: Color {
        switch service.runtimeStatus {
        case .running: return .green
        case .loaded: return .orange
        case .stopped: return .secondary
        }
    }

    private func infoBadge(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.appCaption)
                .lineLimit(1)
        }
    }
}
