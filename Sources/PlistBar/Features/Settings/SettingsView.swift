import SwiftUI

struct SettingsView: View {
    @State private var heartbeatInterval: Double = 3.0
    @State private var defaultScope: LaunchServiceScope = .userAgents
    @State private var logMonitoringEnabled: Bool = true
    @State private var maxLogLines: Int = 500
    @State private var notificationsEnabled: Bool = true
    @State private var rules: [LogRule] = RuleEngineService.defaultRules()

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutTokens.space8) {
            Text("Settings")
                .font(.appTitle)
                .fontWeight(.bold)

            // General
            settingsSection("General") {
                HStack {
                    Text("Heartbeat interval")
                        .font(.appBody)
                    Spacer()
                    Picker("", selection: $heartbeatInterval) {
                        Text("1s").tag(1.0)
                        Text("3s").tag(3.0)
                        Text("5s").tag(5.0)
                        Text("10s").tag(10.0)
                    }
                    .frame(width: 80)
                }

                HStack {
                    Text("Default scope")
                        .font(.appBody)
                    Spacer()
                    Picker("", selection: $defaultScope) {
                        ForEach(LaunchServiceScope.allCases) { scope in
                            Text(scope.displayName).tag(scope)
                        }
                    }
                    .frame(width: 140)
                }
            }

            // Log Monitoring
            settingsSection("Log Monitoring") {
                Toggle("Enable log monitoring", isOn: $logMonitoringEnabled)

                HStack {
                    Text("Max log lines")
                        .font(.appBody)
                    Spacer()
                    TextField("", value: $maxLogLines, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                }
            }

            // Notifications
            settingsSection("Notifications") {
                Toggle("Enable notifications", isOn: $notificationsEnabled)
            }

            // Alert Rules
            settingsSection("Alert Rules") {
                ForEach(rules) { rule in
                    HStack {
                        Circle()
                            .fill(rule.severity == .error ? Color.red : Color.orange)
                            .frame(width: 6, height: 6)
                        Text(rule.name)
                            .font(.appBody)
                        Spacer()
                        Text(rule.pattern)
                            .font(.appCaption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()
        }
        .padding(LayoutTokens.space8)
        .frame(width: LayoutTokens.panelWidth)
    }

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: LayoutTokens.space4) {
            Text(title)
                .font(.appCaption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            VStack(spacing: LayoutTokens.space4) {
                content()
            }
            .padding(LayoutTokens.space6)
            .background(
                RoundedRectangle(cornerRadius: LayoutTokens.cornerRadius, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
        }
    }
}
