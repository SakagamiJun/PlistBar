import AppKit
import SwiftUI

struct LogViewerView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var viewModel: LogViewerViewModel
    let service: LaunchService?

    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        VStack(spacing: 0) {
            // Tab bar with action tools
            tabBar

            Divider()

            // Search filter bar
            searchBar

            Divider()

            // Log content
            if viewModel.isLoading {
                VStack(spacing: LayoutTokens.space6) {
                    ProgressView()
                        .controlSize(.small)
                    Text(l10n("logs.loading"))
                        .font(.appCaption)
                        .foregroundStyle(ColorTokens.secondaryLabel(isDark: isDark))
                }
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
                    Text(tab.displayName)
                        .font(.appCaption)
                        .fontWeight(viewModel.selectedTab == tab ? .semibold : .regular)
                        .padding(.horizontal, LayoutTokens.space6)
                        .padding(.vertical, LayoutTokens.space2)
                        .background(
                            RoundedRectangle(cornerRadius: LayoutTokens.cornerRadius - 2, style: .continuous)
                                .fill(viewModel.selectedTab == tab
                                      ? ColorTokens.accent.opacity(LayoutTokens.Opacity.tint)
                                      : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutTokens.cornerRadius - 2, style: .continuous)
                                .strokeBorder(
                                    viewModel.selectedTab == tab
                                    ? ColorTokens.accent.opacity(0.4)
                                    : Color.clear,
                                    lineWidth: LayoutTokens.stroke
                                )
                        )
                }
                .buttonStyle(.plain)
            }

            Spacer()

            // Copy logs button
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(viewModel.currentLogText, forType: .string)
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.appCaption)
            }
            .buttonStyle(.plain)
            .help(l10n("logs.tooltip_copy"))

            // Refresh logs button
            Button {
                if let service {
                    viewModel.loadLogs(for: service)
                }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.appCaption)
            }
            .buttonStyle(.plain)
            .help(l10n("logs.tooltip_reload"))
        }
        .menuRowPadding(vertical: LayoutTokens.space4)
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack(spacing: LayoutTokens.space4) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(ColorTokens.tertiaryLabel(isDark: isDark))
                .font(.appCaption)

            TextField(l10n("logs.search_placeholder"), text: $viewModel.searchText)
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
        .menuRowPadding(vertical: LayoutTokens.space2)
    }

    // MARK: - Log content

    private var logContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 1) {
                ForEach(Array(viewModel.filteredLines.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.app(size: LayoutTokens.FontSize.caption))
                        .foregroundStyle(logLineColor(line))
                        .textSelection(.enabled)
                        .lineLimit(nil)
                        .padding(.horizontal, LayoutTokens.space6)
                        .padding(.vertical, 0.5)
                }
            }
            .padding(.vertical, LayoutTokens.space4)
        }
    }

    private func logLineColor(_ line: String) -> Color {
        let lower = line.lowercased()
        if lower.contains("error") || lower.contains("fatal") || lower.contains("crash") {
            return ColorTokens.critical
        } else if lower.contains("warn") {
            return ColorTokens.warning
        } else {
            return ColorTokens.primaryLabel(isDark: isDark)
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: LayoutTokens.space4) {
            Image(systemName: "doc.text")
                .font(.appTitle)
                .foregroundStyle(ColorTokens.tertiaryLabel(isDark: isDark))
            Text(l10n("logs.empty"))
                .font(.appBody)
                .foregroundStyle(ColorTokens.secondaryLabel(isDark: isDark))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, LayoutTokens.space8)
    }
}
