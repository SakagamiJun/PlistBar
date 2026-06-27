import SwiftUI

struct AlertBannerView: View {
    @Bindable var alertViewModel: AlertViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: alertViewModel.hasError ? "exclamationmark.triangle.fill" : "bell.fill")
                    .foregroundStyle(alertViewModel.hasError ? .red : .orange)
                    .font(.appBody)

                Text("Alerts")
                    .font(.appSubhead)
                    .fontWeight(.semibold)

                if alertViewModel.hasUnread {
                    Text("\(alertViewModel.unreadCount)")
                        .font(.appCaption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.red))
                        .foregroundStyle(.white)
                }

                Spacer()

                if !alertViewModel.alerts.isEmpty {
                    Button("Mark Read") { alertViewModel.markAllRead() }
                        .font(.appCaption)
                        .buttonStyle(.plain)

                    Button("Clear") { alertViewModel.clear() }
                        .font(.appCaption)
                        .buttonStyle(.plain)
                }
            }
            .menuRowPadding()

            Divider()

            // Alert list
            if alertViewModel.alerts.isEmpty {
                VStack {
                    Image(systemName: "checkmark.circle")
                        .font(.appTitle)
                        .foregroundStyle(.green)
                    Text("No alerts")
                        .font(.appBody)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        HStack(alignment: .top, spacing: LayoutTokens.space4) {
            Circle()
                .fill(alert.severity == .error ? Color.red : Color.orange)
                .frame(width: 6, height: 6)
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 1) {
                HStack {
                    Text(alert.jobLabel)
                        .font(.appCaption)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(alert.timestamp, style: .time)
                        .font(.appCaption)
                        .foregroundStyle(.tertiary)
                }

                Text(alert.matchedLine)
                    .font(.app(size: LayoutTokens.FontSize.caption))
                    .lineLimit(3)
                    .foregroundStyle(alert.isRead ? .tertiary : .primary)
            }
        }
        .menuRowPadding(vertical: LayoutTokens.space4)
        .opacity(alert.isRead ? 0.6 : 1.0)
    }
}
