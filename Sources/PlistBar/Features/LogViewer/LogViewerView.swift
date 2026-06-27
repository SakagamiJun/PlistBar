import SwiftUI

struct LogViewerView: View {
    @Bindable var viewModel: LogViewerViewModel
    let service: LaunchService?

    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            tabBar

            Divider()

            // Search bar
            searchBar

            Divider()

            // Log content
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.filteredLines.isEmpty {
                emptyState
            } else {
                logContent
            }
        }
        .onChange(of: service?.id) { _, _ in
            if let service {
                viewModel.loadLogs(for: service)
            }
        }
    }

    // MARK: - Tab bar

    private var tabBar: some View {
        HStack(spacing: LayoutTokens.space2) {
            ForEach(LogViewerViewModel.LogTab.allCases) { tab in
                Button {
                    viewModel.selectedTab = tab
                } label: {
                    Text(tab.rawValue)
                        .font(.appCaption)
                        .fontWeight(viewModel.selectedTab == tab ? .semibold : .regular)
                        .padding(.horizontal, LayoutTokens.space6)
                        .padding(.vertical, LayoutTokens.space2)
                        .background(
                            RoundedRectangle(cornerRadius: LayoutTokens.cornerRadius - 2, style: .continuous)
                                .fill(viewModel.selectedTab == tab
                                      ? Color.accentColor.opacity(LayoutTokens.Opacity.tint)
                                      : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Button {
                if let service {
                    viewModel.loadLogs(for: service)
                }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.appCaption)
            }
            .buttonStyle(.plain)
            .help("Refresh logs")
        }
        .menuRowPadding(vertical: LayoutTokens.space4)
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack(spacing: LayoutTokens.space4) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.tertiary)
                .font(.appCaption)

            TextField("Filter logs...", text: $viewModel.searchText)
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
        .menuRowPadding(vertical: LayoutTokens.space2)
    }

    // MARK: - Log content

    private var logContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(Array(viewModel.filteredLines.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.app(size: LayoutTokens.FontSize.caption))
                        .textSelection(.enabled)
                        .lineLimit(nil)
                        .padding(.horizontal, LayoutTokens.space4)
                        .padding(.vertical, 1)
                }
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: LayoutTokens.space4) {
            Image(systemName: "doc.text")
                .font(.appTitle)
                .foregroundStyle(.tertiary)
            Text("No log output")
                .font(.appBody)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
