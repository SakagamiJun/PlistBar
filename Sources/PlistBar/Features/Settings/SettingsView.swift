import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var alertViewModel: AlertViewModel
    var onBack: (() -> Void)? = nil

    @AppStorage("plistbar.heartbeat_interval") private var heartbeatInterval: Double = 3.0
    @AppStorage("plistbar.default_scope") private var defaultScopeRaw: String = LaunchServiceScope.userAgents.rawValue
    @AppStorage("plistbar.notifications_enabled") private var notificationsEnabled: Bool = true
    @AppStorage("plistbar.max_log_lines") private var maxLogLines: Int = 500

    @State private var localizationManager = LocalizationManager.shared
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
                            Text(l10n("action.back"))
                        }
                        .font(.appCaption)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(ColorTokens.accent)
                }

                Text(l10n("settings.title"))
                    .font(.appSubhead)
                    .fontWeight(.semibold)

                Spacer()
            }
            .menuRowPadding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: LayoutTokens.space8) {
                    // Language
                    settingsSection(l10n("settings.section.language")) {
                        HStack {
                            Text(l10n("settings.language"))
                                .font(.appBody)
                            Spacer()
                            Picker("", selection: Binding(
                                get: { localizationManager.selectedLanguage },
                                set: { localizationManager.setLanguage($0) }
                            )) {
                                ForEach(AppLanguage.allCases) { lang in
                                    Text(lang.displayName).tag(lang)
                                }
                            }
                            .frame(width: 150)
                        }
                    }

                    // General
                    settingsSection(l10n("settings.section.polling_scope")) {
                        HStack {
                            Text(l10n("settings.heartbeat_interval"))
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
                            Text(l10n("settings.default_scope"))
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
                    settingsSection(l10n("settings.section.notifications")) {
                        Toggle(l10n("settings.show_notifications"), isOn: $notificationsEnabled)
                            .font(.appBody)
                            .onChange(of: notificationsEnabled) { _, enabled in
                                if enabled {
                                    Task { _ = await NotificationService.requestPermission() }
                                }
                            }
                    }

                    // Log Rules Management
                    settingsSection(l10n("settings.section.log_rules")) {
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
                                            Text(l10n("action.add_rule"))
                                        }
                                        .font(.appCaption)
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundStyle(ColorTokens.accent)

                                    Spacer()

                                    Button(l10n("action.reset_defaults")) {
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
                    settingsSection(l10n("settings.section.about")) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(l10n("app.name"))
                                    .font(.appBody)
                                    .fontWeight(.medium)
                                Text(l10n("app.tagline"))
                                    .font(.system(size: 9))
                                    .foregroundStyle(ColorTokens.tertiaryLabel(isDark: isDark))
                            }
                            Spacer()
                            Text(l10n("app.version"))
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
                TextField(l10n("settings.rule_name_placeholder"), text: $newRuleName)
                    .textFieldStyle(.roundedBorder)
                    .font(.appCaption)

                Picker("", selection: $newRuleSeverity) {
                    ForEach(LogRule.Severity.allCases, id: \.self) { sev in
                        Text(sev.displayName).tag(sev)
                    }
                }
                .frame(width: 80)
            }

            TextField(l10n("settings.rule_pattern_placeholder"), text: $newRulePattern)
                .textFieldStyle(.roundedBorder)
                .font(.appCaption)

            HStack {
                Button(l10n("action.cancel")) {
                    showingAddRule = false
                    newRuleName = ""
                    newRulePattern = ""
                }
                .font(.appCaption)
                .buttonStyle(.bordered)
                .controlSize(.mini)

                Spacer()

                Button(l10n("action.save_rule")) {
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
