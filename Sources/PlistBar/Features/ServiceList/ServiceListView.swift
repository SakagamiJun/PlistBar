import SwiftUI

struct ServiceListView: View {
    @Bindable var viewModel: ServiceListViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            Divider()

            // Scope filter bar
            ScopeFilterBar(
                selectedScope: $viewModel.selectedScope,
                statusFilter: $viewModel.statusFilter
            )

            Divider()

            // Service list
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.filteredServices.isEmpty {
                emptyState
            } else {
                serviceList
            }

            // Action status banner
            if let status = viewModel.actionStatus {
                Divider()
                actionBanner(status)
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: LayoutTokens.panelCornerRadius, style: .continuous))
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Image(systemName: "list.bullet.rectangle")
                .font(.appSubhead)
                .foregroundStyle(.secondary)

            Text("PlistBar")
                .font(.appSubhead)
                .fontWeight(.semibold)

            Spacer()

            Button {
                viewModel.refresh()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.appBody)
            }
            .buttonStyle(.plain)
            .help("Refresh services")
        }
        .menuRowPadding()
    }

    // MARK: - Search bar integrated into list

    private var serviceList: some View {
        List(selection: $viewModel.selectedService) {
            Section {
                ForEach(viewModel.filteredServices) { service in
                    ServiceRowView(
                        service: service,
                        isSelected: viewModel.selectedService?.id == service.id,
                        onSelect: {
                            viewModel.selectedService = service
                        },
                        onStart: {
                            viewModel.runAction(LaunchctlService.start, label: "Starting")
                        },
                        onStop: {
                            viewModel.runAction(LaunchctlService.stop, label: "Stopping")
                        }
                    )
                    .tag(service)
                }
            } header: {
                searchBar
            }
        }
        .listStyle(.sidebar)
    }

    private var searchBar: some View {
        HStack(spacing: LayoutTokens.space4) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.tertiary)
                .font(.appCaption)

            TextField("Search services...", text: $viewModel.searchText)
                .textFieldStyle(.plain)
                .font(.appBody)

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                        .font(.appCaption)
                }
                .buttonStyle(.plain)
            }
        }
        .menuRowPadding(vertical: LayoutTokens.space4)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: LayoutTokens.space8) {
            Image(systemName: "tray")
                .font(.appTitle)
                .foregroundStyle(.tertiary)
            Text("No services found")
                .font(.appBody)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Action banner

    private func actionBanner(_ status: ActionStatus) -> some View {
        HStack(spacing: LayoutTokens.space4) {
            switch status {
            case .inProgress(let msg):
                ProgressView()
                    .controlSize(.small)
                Text(msg).font(.appCaption)
            case .success(let msg):
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text(msg).font(.appCaption)
            case .failure(let msg):
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                Text(msg).font(.appCaption)
                    .lineLimit(2)
            }
            Spacer()
        }
        .menuRowPadding(vertical: LayoutTokens.space4)
        .background(status == .failure("") ? Color.red.opacity(0.1) : Color.clear)
    }
}
