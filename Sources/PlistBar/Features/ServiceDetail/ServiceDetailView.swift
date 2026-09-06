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
                        Text(l10n("action.back"))
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
                .help(l10n("detail.tooltip_reveal"))

                if service.scope.isUserWritable {
                    Button(l10n("action.edit")) { onEdit() }
                        .font(.appCaption)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                } else {
                    Text(l10n("detail.read_only"))
                        .font(.system(size: 9, weight: .semibold))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(ColorTokens.controlFill(isDark: isDark)))
                        .foregroundStyle(ColorTokens.tertiaryLabel(isDark: isDark))
                        .help(l10n("detail.read_only_tooltip"))
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
                infoBadge(l10n("detail.badge.scope"), service.scope.displayName)
                infoBadge(l10n("detail.badge.status"), service.runtimeStatus.displayName)
                if let pid = service.pid {
                    infoBadge(l10n("detail.badge.pid"), "\(pid)")
                }
                infoBadge(l10n("detail.badge.enabled"), service.enabled ? l10n("common.yes") : l10n("common.no"))
                infoBadge(l10n("detail.badge.run_at_load"), service.runAtLoad ? l10n("common.yes") : l10n("common.no"))
                infoBadge(l10n("detail.badge.keep_alive"), service.keepAlive ? l10n("common.yes") : l10n("common.no"))
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
                    title: l10n("detail.confirm_stop_title"),
                    message: l10n("detail.confirm_stop_msg", service.label),
                    destructive: true
                ) {
                    viewModel.runAction(LaunchctlService.stop, label: l10n("status.stopping"))
                }

            case .loaded, .stopped:
                Button(l10n("action.start")) {
                    viewModel.runAction(LaunchctlService.start, label: l10n("status.starting"))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            if service.enabled {
                Button(l10n("action.disable")) {
                    viewModel.runAction(LaunchctlService.disable, label: l10n("status.disabling"))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            } else {
                Button(l10n("action.enable")) {
                    viewModel.runAction(LaunchctlService.enable, label: l10n("status.enabling"))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            Button(l10n("action.load")) {
                viewModel.runAction(LaunchctlService.load, label: l10n("status.loading"))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Button(l10n("action.unload")) {
                viewModel.runAction(LaunchctlService.unload, label: l10n("status.unloading"))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            if service.scope.isUserWritable {
                ConfirmButton(
                    title: l10n("detail.confirm_delete_title"),
                    message: l10n("detail.confirm_delete_msg", service.label),
                    destructive: true
                ) {
                    viewModel.runAction(LaunchctlService.deleteUserAgent, label: l10n("status.deleting"))
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
