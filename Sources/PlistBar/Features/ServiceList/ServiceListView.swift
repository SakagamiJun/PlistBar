import SwiftUI

enum EditorMode: Equatable {
    case new(draft: LaunchPlistDraft)
    case edit(serviceId: String)

    static func == (lhs: EditorMode, rhs: EditorMode) -> Bool {
        switch (lhs, rhs) {
        case (.new(let a), .new(let b)):
            return a.label == b.label
        case (.edit(let a), .edit(let b)):
            return a == b
        default:
            return false
        }
    }
}

enum PanelScreen: Equatable {
    case list
    case detail(serviceId: String)
    case templatePicker
    case editor(mode: EditorMode)
    case alerts
    case settings

    static func == (lhs: PanelScreen, rhs: PanelScreen) -> Bool {
        switch (lhs, rhs) {
        case (.list, .list): return true
        case (.templatePicker, .templatePicker): return true
        case (.alerts, .alerts): return true
        case (.settings, .settings): return true
        case (.detail(let a), .detail(let b)): return a == b
        case (.editor(let a), .editor(let b)): return a == b
        default: return false
        }
    }
}

struct ServiceListView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var viewModel: ServiceListViewModel
    @Bindable var alertViewModel: AlertViewModel

    @State private var activeScreen: PanelScreen = .list
    @State private var logViewModel = LogViewerViewModel()
    @State private var editorViewModel = EditorViewModel()
    @State private var isSearchExpanded = false

    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        VStack(spacing: 0) {
            switch activeScreen {
            case .list:
                mainListView
            case .detail(let serviceId):
                if let service = viewModel.services.first(where: { $0.id == serviceId }) {
                    ServiceDetailView(
                        service: service,
                        viewModel: viewModel,
                        logViewModel: logViewModel,
                        alertViewModel: alertViewModel,
                        onBack: {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                activeScreen = .list
                            }
                        },
                        onEdit: {
                            editorViewModel.loadFromService(service)
                            withAnimation(.easeInOut(duration: 0.18)) {
                                activeScreen = .editor(mode: .edit(serviceId: service.id))
                            }
                        }
                    )
                } else {
                    missingServiceView
                }

            case .templatePicker:
                TemplatePicker(
                    onSelect: { draft in
                        editorViewModel.draft = draft
                        editorViewModel.isRawXMLMode = false
                        withAnimation(.easeInOut(duration: 0.18)) {
                            activeScreen = .editor(mode: .new(draft: draft))
                        }
                    },
                    onCancel: {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            activeScreen = .list
                        }
                    }
                )

            case .editor(let mode):
                ServiceEditorView(
                    viewModel: editorViewModel,
                    onSave: {
                        handleSaveEditor(mode: mode)
                    },
                    onCancel: {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            switch mode {
                            case .new:
                                activeScreen = .list
                            case .edit(let serviceId):
                                activeScreen = .detail(serviceId: serviceId)
                            }
                        }
                    }
                )

            case .alerts:
                AlertBannerView(
                    alertViewModel: alertViewModel,
                    onBack: {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            activeScreen = .list
                        }
                    },
                    onSelectService: { label in
                        if let svc = viewModel.services.first(where: { $0.label == label }) {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                activeScreen = .detail(serviceId: svc.id)
                            }
                        }
                    }
                )

            case .settings:
                SettingsView(
                    alertViewModel: alertViewModel,
                    onBack: {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            activeScreen = .list
                        }
                    }
                )
            }
        }
        .frame(width: LayoutTokens.panelWidth, height: 460)
        .clipShape(RoundedRectangle(cornerRadius: LayoutTokens.panelCornerRadius, style: .continuous))
    }

    // MARK: - Main List View

    private var mainListView: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            // Search bar (if expanded or text entered)
            if isSearchExpanded || !viewModel.searchText.isEmpty {
                Divider()
                inlineSearchBar
            }

            // Unread Alert Notification Banner
            AlertSummaryBanner(alertViewModel: alertViewModel) {
                withAnimation(.easeInOut(duration: 0.18)) {
                    activeScreen = .alerts
                }
            }

            Divider()

            // Scope filter bar
            ScopeFilterBar(
                selectedScope: $viewModel.selectedScope,
                statusFilter: $viewModel.statusFilter,
                scopeCounts: scopeCounts
            )

            Divider()

            // Service list
            if viewModel.isLoading && viewModel.services.isEmpty {
                loadingView
            } else if viewModel.filteredServices.isEmpty {
                emptyState
            } else {
                serviceScrollView
            }

            // Action status banner
            if let status = viewModel.actionStatus {
                Divider()
                actionBanner(status)
            }

            Divider()

            // Bottom bar
            bottomBar
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: LayoutTokens.space6) {
            Image(systemName: "list.bullet.rectangle")
                .font(.appSubhead)
                .foregroundStyle(ColorTokens.accent)

            Text("PlistBar")
                .font(.appSubhead)
                .fontWeight(.bold)
                .foregroundStyle(ColorTokens.primaryLabel(isDark: isDark))

            let runningCount = viewModel.services.filter { $0.runtimeStatus == .running }.count
            if runningCount > 0 {
                HStack(spacing: 3) {
                    Circle()
                        .fill(ColorTokens.positive)
                        .frame(width: 5, height: 5)
                    Text("\(runningCount)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(ColorTokens.positive)
                }
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
                .background(
                    Capsule().fill(ColorTokens.positive.opacity(LayoutTokens.Opacity.tint))
                )
            }

            Spacer()

            // Search toggle
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isSearchExpanded.toggle()
                }
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.appBody)
                    .foregroundStyle(
                        isSearchExpanded || !viewModel.searchText.isEmpty
                        ? ColorTokens.accent
                        : ColorTokens.secondaryLabel(isDark: isDark)
                    )
            }
            .buttonStyle(.plain)
            .help(l10n("list.tooltip_search"))

            // Alerts icon
            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    activeScreen = .alerts
                }
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: alertViewModel.hasUnread ? "bell.badge.fill" : "bell")
                        .font(.appBody)
                        .foregroundStyle(
                            alertViewModel.hasError
                            ? ColorTokens.critical
                            : (alertViewModel.hasUnread ? ColorTokens.warning : ColorTokens.secondaryLabel(isDark: isDark))
                        )
                }
            }
            .buttonStyle(.plain)
            .help(l10n("list.tooltip_alerts"))

            // Settings icon
            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    activeScreen = .settings
                }
            } label: {
                Image(systemName: "gearshape")
                    .font(.appBody)
                    .foregroundStyle(ColorTokens.secondaryLabel(isDark: isDark))
            }
            .buttonStyle(.plain)
            .help(l10n("list.tooltip_settings"))

            // Refresh icon
            Button {
                viewModel.refresh()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.appBody)
                    .foregroundStyle(ColorTokens.secondaryLabel(isDark: isDark))
            }
            .buttonStyle(.plain)
            .help(l10n("list.tooltip_refresh"))
        }
        .menuRowPadding()
    }

    // MARK: - Inline Search Bar

    private var inlineSearchBar: some View {
        HStack(spacing: LayoutTokens.space4) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(ColorTokens.tertiaryLabel(isDark: isDark))
                .font(.appCaption)

            TextField(l10n("list.search_placeholder"), text: $viewModel.searchText)
                .textFieldStyle(.plain)
                .font(.appBody)

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(ColorTokens.tertiaryLabel(isDark: isDark))
                        .font(.appCaption)
                }
                .buttonStyle(.plain)
            }
        }
        .menuRowPadding(vertical: LayoutTokens.space4)
        .background(ColorTokens.controlFill(isDark: isDark))
    }

    // MARK: - Service Scroll View

    private var serviceScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                ForEach(viewModel.filteredServices) { service in
                    ServiceRowView(
                        service: service,
                        isSelected: viewModel.selectedService?.id == service.id,
                        onSelect: {
                            viewModel.selectedService = service
                            withAnimation(.easeInOut(duration: 0.18)) {
                                activeScreen = .detail(serviceId: service.id)
                            }
                        },
                        onStart: {
                            viewModel.runAction(LaunchctlService.start, label: l10n("status.starting"))
                        },
                        onStop: {
                            viewModel.runAction(LaunchctlService.stop, label: l10n("status.stopping"))
                        },
                        onToggleEnable: {
                            if service.enabled {
                                viewModel.runAction(LaunchctlService.disable, label: l10n("status.disabling"))
                            } else {
                                viewModel.runAction(LaunchctlService.enable, label: l10n("status.enabling"))
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, LayoutTokens.space4)
            .padding(.vertical, LayoutTokens.space2)
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    activeScreen = .templatePicker
                }
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: "plus")
                    Text(l10n("list.new_service"))
                }
                .font(.appCaption)
                .fontWeight(.medium)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)

            Spacer()

            let total = viewModel.filteredServices.count
            Text(total == 1 ? l10n("list.service_count_single") : l10n("list.service_count", total))
                .font(.system(size: 10))
                .foregroundStyle(ColorTokens.tertiaryLabel(isDark: isDark))
        }
        .menuRowPadding(vertical: LayoutTokens.space6)
    }

    // MARK: - Empty & Loading States

    private var emptyState: some View {
        VStack(spacing: LayoutTokens.space6) {
            Image(systemName: "tray")
                .font(.system(size: 30))
                .foregroundStyle(ColorTokens.tertiaryLabel(isDark: isDark))
            Text(l10n("list.empty"))
                .font(.appBody)
                .foregroundStyle(ColorTokens.secondaryLabel(isDark: isDark))

            if !viewModel.searchText.isEmpty {
                Button(l10n("action.clear_search")) {
                    viewModel.searchText = ""
                }
                .font(.appCaption)
                .buttonStyle(.bordered)
                .controlSize(.mini)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 32)
    }

    private var loadingView: some View {
        VStack(spacing: LayoutTokens.space4) {
            ProgressView()
                .controlSize(.small)
            Text(l10n("list.loading"))
                .font(.appCaption)
                .foregroundStyle(ColorTokens.secondaryLabel(isDark: isDark))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var missingServiceView: some View {
        VStack(spacing: LayoutTokens.space6) {
            Text(l10n("list.not_found"))
                .font(.appBody)
                .foregroundStyle(ColorTokens.secondaryLabel(isDark: isDark))

            Button(l10n("action.back_to_list")) {
                withAnimation(.easeInOut(duration: 0.18)) {
                    activeScreen = .list
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Action Banner

    private func actionBanner(_ status: ActionStatus) -> some View {
        HStack(spacing: LayoutTokens.space4) {
            switch status {
            case .inProgress(let msg):
                ProgressView()
                    .controlSize(.small)
                Text(msg)
                    .font(.appCaption)
                    .foregroundStyle(ColorTokens.secondaryLabel(isDark: isDark))
            case .success(let msg):
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(ColorTokens.positive)
                Text(msg)
                    .font(.appCaption)
                    .foregroundStyle(ColorTokens.positive)
            case .failure(let msg):
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(ColorTokens.critical)
                Text(msg)
                    .font(.appCaption)
                    .foregroundStyle(ColorTokens.critical)
                    .lineLimit(2)
            }
            Spacer()
        }
        .menuRowPadding(vertical: LayoutTokens.space4)
        .background(
            (status == .failure("") ? ColorTokens.critical.opacity(0.12) : ColorTokens.controlFill(isDark: isDark))
        )
    }

    // MARK: - Helpers

    private var scopeCounts: [LaunchServiceScope: Int] {
        var counts: [LaunchServiceScope: Int] = [:]
        for service in viewModel.services {
            counts[service.scope, default: 0] += 1
        }
        return counts
    }

    private func handleSaveEditor(mode: EditorMode) {
        switch mode {
        case .new:
            do {
                _ = try editorViewModel.createNewUserAgent()
                viewModel.refresh()
                withAnimation(.easeInOut(duration: 0.18)) {
                    activeScreen = .list
                }
            } catch {
                // error message is set on editorViewModel
            }

        case .edit(let serviceId):
            if let service = viewModel.services.first(where: { $0.id == serviceId }) {
                if editorViewModel.save(to: service) {
                    viewModel.refresh()
                    withAnimation(.easeInOut(duration: 0.18)) {
                        activeScreen = .detail(serviceId: serviceId)
                    }
                }
            }
        }
    }
}
