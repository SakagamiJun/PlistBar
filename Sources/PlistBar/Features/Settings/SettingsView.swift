import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var alertViewModel: AlertViewModel
    var onBack: (() -> Void)? = nil

    @AppStorage("plistbar.heartbeat_interval") private var heartbeatInterval: Double = 3.0
    @AppStorage("plistbar.default_scope") private var defaultScopeRaw: String = LaunchServiceScope.userAgents.rawValue
    @AppStorage("plistbar.notifications_enabled") private var notificationsEnabled: Bool = true
    @AppStorage("plistbar.max_log_lines") private var maxLogLines: Int = 500

    @State private var showingAddRule = false
    @State private var newRuleName = ""
    @State private var newRulePattern = ""
    @State private var newRuleSeverity: LogRule.Severity = .error

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

                Text("Settings")
                    .font(.appSubhead)
                    .fontWeight(.semibold)

                Spacer()
            }
            .menuRowPadding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: LayoutTokens.space8) {
                    // General
                    settingsSection("Polling & Scope") {
                        HStack {
                            Text("Heartbeat Interval")
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
                            Text("Default Scope")
                                .font(.appBody)
                            Spacer()
                            Picker("", selection: $defaultScopeRaw) {
                                ForEach(LaunchServiceScope.allCases) { scope in
                                    Text(scope.displayName).tag(scope.rawValue)
                                }
                            }
                            .frame(width: 140)
                        }
                    }

                    // System Notifications
                    settingsSection("Notifications") {
                        Toggle("Show System Notifications", isOn: $notificationsEnabled)
                            .font(.appBody)
                            .onChange(of: notificationsEnabled) { _, enabled in
                                if enabled {
                                    Task { _ = await NotificationService.requestPermission() }
                                }
                            }
                    }

                    // Log Rules Management
                    settingsSection("Log Alert Rules") {
                        VStack(spacing: LayoutTokens.space4) {
                            ForEach(alertViewModel.rules) { rule in
                                HStack(spacing: LayoutTokens.space4) {
                                    Circle()
                                        .fill(rule.severity == .error ? ColorTokens.critical : ColorTokens.warning)
                                        .frame(width: 6, height: 6)

                                    Toggle(isOn: Binding(
                                        get: { rule.isEnabled },
                                        set: { _ in alertViewModel.toggleRule(id: rule.id) }
                                    )) {
                                        Text(rule.name)
                                            .font(.appCaption)
                                            .fontWeight(.medium)
                                    }

                                    Spacer()

                                    Text(rule.pattern)
                                        .font(.system(size: 9))
                                        .foregroundStyle(ColorTokens.tertiaryLabel(isDark: isDark))
                                        .lineLimit(1)

                                    Button {
                                        alertViewModel.deleteRule(id: rule.id)
                                    } label: {
                                        Image(systemName: "trash")
                                            .font(.system(size: 9))
                                            .foregroundStyle(ColorTokens.critical.opacity(0.8))
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.vertical, 1)
                            }

                            Divider().padding(.vertical, 2)

                            if showingAddRule {
                                addRuleForm
                            } else {
                                HStack {
                                    Button {
                                        showingAddRule = true
                                    } label: {
                                        HStack(spacing: 2) {
                                            Image(systemName: "plus.circle")
                                            Text("Add Rule")
                                        }
                                        .font(.appCaption)
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundStyle(ColorTokens.accent)

                                    Spacer()

                                    Button("Reset to Defaults") {
                                        alertViewModel.resetRulesToDefault()
                                    }
                                    .font(.system(size: 9))
                                    .buttonStyle(.plain)
                                    .foregroundStyle(ColorTokens.tertiaryLabel(isDark: isDark))
                                }
                            }
                        }
                    }

                    // About section
                    settingsSection("About") {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("PlistBar for macOS")
                                    .font(.appBody)
                                    .fontWeight(.medium)
                                Text("Lightweight launchd manager with memory safety")
                                    .font(.system(size: 9))
                                    .foregroundStyle(ColorTokens.tertiaryLabel(isDark: isDark))
                            }
                            Spacer()
                            Text("v1.0.0")
                                .font(.appCaption)
                                .foregroundStyle(ColorTokens.tertiaryLabel(isDark: isDark))
                        }
                    }
                }
                .padding(LayoutTokens.space8)
            }
        }
    }

    private var addRuleForm: some View {
        VStack(alignment: .leading, spacing: LayoutTokens.space4) {
            HStack {
                TextField("Rule Name (e.g. Timeout)", text: $newRuleName)
                    .textFieldStyle(.roundedBorder)
                    .font(.appCaption)

                Picker("", selection: $newRuleSeverity) {
                    Text("Error").tag(LogRule.Severity.error)
                    Text("Warning").tag(LogRule.Severity.warning)
                    Text("Info").tag(LogRule.Severity.info)
                }
                .frame(width: 80)
            }

            TextField("Regex Pattern (e.g. (?i)\\btimeout\\b)", text: $newRulePattern)
                .textFieldStyle(.roundedBorder)
                .font(.appCaption)

            HStack {
                Button("Cancel") {
                    showingAddRule = false
                    newRuleName = ""
                    newRulePattern = ""
                }
                .font(.appCaption)
                .buttonStyle(.bordered)
                .controlSize(.mini)

                Spacer()

                Button("Save Rule") {
                    let trimmedName = newRuleName.trimmingCharacters(in: .whitespaces)
                    let trimmedPattern = newRulePattern.trimmingCharacters(in: .whitespaces)
                    guard !trimmedName.isEmpty, !trimmedPattern.isEmpty else { return }
                    alertViewModel.addRule(name: trimmedName, pattern: trimmedPattern, severity: newRuleSeverity)
                    showingAddRule = false
                    newRuleName = ""
                    newRulePattern = ""
                }
                .font(.appCaption)
                .buttonStyle(.borderedProminent)
                .controlSize(.mini)
                .disabled(newRuleName.isEmpty || newRulePattern.isEmpty)
            }
        }
        .padding(LayoutTokens.space4)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(ColorTokens.controlFill(isDark: isDark))
        )
    }

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: LayoutTokens.space4) {
            Text(title)
                .font(.appCaption)
                .fontWeight(.semibold)
                .foregroundStyle(ColorTokens.secondaryLabel(isDark: isDark))

            VStack(spacing: LayoutTokens.space4) {
                content()
            }
            .padding(LayoutTokens.space6)
            .background(
                RoundedRectangle(cornerRadius: LayoutTokens.cornerRadius, style: .continuous)
                    .fill(ColorTokens.controlFill(isDark: isDark))
            )
        }
    }
}
