import SwiftUI

/// Compact alert banner shown conditionally at the top of the service list
struct AlertSummaryBanner: View {
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var alertViewModel: AlertViewModel
    let onViewAlerts: () -> Void

    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        guard alertViewModel.hasUnread else { return AnyView(EmptyView()) }

        let isError = alertViewModel.hasError
        let bannerColor = isError ? ColorTokens.critical : ColorTokens.warning

        return AnyView(
            Button(action: onViewAlerts) {
                HStack(spacing: LayoutTokens.space6) {
                    Image(systemName: isError ? "exclamationmark.triangle.fill" : "exclamationmark.circle.fill")
                        .foregroundStyle(bannerColor)
                        .font(.appBody)

                    Text("\(alertViewModel.unreadCount) unread alert\(alertViewModel.unreadCount > 1 ? "s" : "")")
                        .font(.appCaption)
                        .fontWeight(.medium)
                        .foregroundStyle(ColorTokens.primaryLabel(isDark: isDark))

                    Spacer()

                    HStack(spacing: 2) {
                        Text("View")
                            .font(.appCaption)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 8))
                    }
                    .foregroundStyle(bannerColor)
                }
                .menuRowPadding(vertical: LayoutTokens.space4)
                .background(bannerColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: LayoutTokens.cornerRadius - 2, style: .continuous))
                .padding(.horizontal, LayoutTokens.space4)
                .padding(.vertical, 2)
            }
            .buttonStyle(.plain)
        )
    }
}

/// Full alerts view with back navigation, filtering, mark read, and clear
struct AlertBannerView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var alertViewModel: AlertViewModel
    var onBack: (() -> Void)? = nil
    var onSelectService: ((String) -> Void)? = nil

    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: LayoutTokens.space4) {
                if let onBack {
                    Button(action: onBack) {
                        HStack(spacing: 2) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.appCaption)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(ColorTokens.accent)
                }

                Text("Alerts")
                    .font(.appSubhead)
                    .fontWeight(.semibold)

                if alertViewModel.hasUnread {
                    Text("\(alertViewModel.unreadCount)")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(ColorTokens.critical))
                        .foregroundStyle(.white)
                }

                Spacer()

                if !alertViewModel.alerts.isEmpty {
                    Button("Mark Read") { alertViewModel.markAllRead() }
                        .font(.appCaption)
                        .buttonStyle(.bordered)
                        .controlSize(.mini)

                    Button("Clear") { alertViewModel.clear() }
                        .font(.appCaption)
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                }
            }
            .menuRowPadding()

            Divider()

            // Alert list
            if alertViewModel.alerts.isEmpty {
                VStack(spacing: LayoutTokens.space4) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(ColorTokens.positive)
                    Text("No alerts triggered")
                        .font(.appBody)
                        .foregroundStyle(ColorTokens.secondaryLabel(isDark: isDark))
                    Text("Real-time log rules monitor stderr/stdout")
                        .font(.appCaption)
                        .foregroundStyle(ColorTokens.tertiaryLabel(isDark: isDark))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 32)
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(alertViewModel.alerts) { alert in
                            alertRow(alert)
                        }
                    }
                }
            }
        }
    }

    private func alertRow(_ alert: AlertItem) -> some View {
        Button {
            onSelectService?(alert.jobLabel)
        } label: {
            HStack(alignment: .top, spacing: LayoutTokens.space6) {
                Circle()
                    .fill(alert.severity == .error ? ColorTokens.critical : ColorTokens.warning)
                    .frame(width: 7, height: 7)
                    .padding(.top, 4)

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(alert.jobLabel)
                            .font(.appCaption)
                            .fontWeight(.semibold)
                            .foregroundStyle(ColorTokens.primaryLabel(isDark: isDark))

                        Text("[\(alert.ruleName)]")
                            .font(.system(size: 9))
                            .foregroundStyle(alert.severity == .error ? ColorTokens.critical : ColorTokens.warning)

                        Spacer()

                        Text(alert.timestamp, style: .time)
                            .font(.system(size: 9))
                            .foregroundStyle(ColorTokens.tertiaryLabel(isDark: isDark))
                    }

                    Text(alert.matchedLine)
                        .font(.app(size: LayoutTokens.FontSize.caption))
                        .lineLimit(3)
                        .foregroundStyle(alert.isRead ? ColorTokens.tertiaryLabel(isDark: isDark) : ColorTokens.primaryLabel(isDark: isDark))
                }
            }
            .menuRowPadding(vertical: LayoutTokens.space4)
            .background(alert.isRead ? Color.clear : ColorTokens.controlFill(isDark: isDark))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
