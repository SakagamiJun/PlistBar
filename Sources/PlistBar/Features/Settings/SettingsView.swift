import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var alertViewModel: AlertViewModel
    var onBack: (() -> Void)? = nil

    @AppStorage("plistbar.heartbeat_interval") private var heartbeatInterval: Double = 3.0
    @AppStorage("plistbar.default_scope") private var defaultScopeRaw: String = LaunchServiceScope.userAgents.rawValue
    @AppStorage("plistbar.notifications_enabled") private var notificationsEnabled: Bool = true
    @AppStorage("plistbar.max_log_lines") private var maxLogLines: Int = 500

    enum RuleMatchType: String, CaseIterable, Identifiable {
        case contains = "contains"
        case exactWord = "exact_word"
        case prefix = "prefix"
        case suffix = "suffix"
        case regex = "regex"

        var id: String { rawValue }

        @MainActor
        var displayName: String {
            switch self {
            case .contains: return l10n("settings.match_type.contains")
            case .exactWord: return l10n("settings.match_type.exact_word")
            case .prefix: return l10n("settings.match_type.prefix")
            case .suffix: return l10n("settings.match_type.suffix")
            case .regex: return l10n("settings.match_type.regex")
            }
        }
    }

    private static let rulePresets: [(name: String, keyword: String, severity: LogRule.Severity)] = [
        ("Crash", "crash", .error),
        ("Timeout", "timeout", .warning),
        ("Permission denied", "permission denied", .error),
        ("Connection refused", "connection refused", .warning),
        ("Out of memory", "out of memory", .error),
        ("Failed", "failed", .warning),
    ]

    @State private var localizationManager = LocalizationManager.shared
    @State private var showingAddRule = false
    @State private var newRuleName = ""
    @State private var newRulePattern = ""
    @State private var newRuleKeyword = ""
    @State private var newRuleMatchType: RuleMatchType = .contains
    @State private var newRuleCaseSensitive = false
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
                            .toggleStyle(.switch)
                            .controlSize(.small)
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
                                    .toggleStyle(.switch)
                                    .controlSize(.mini)

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

    private var generatedPattern: String {
        switch newRuleMatchType {
        case .regex:
            return newRulePattern.trimmingCharacters(in: .whitespaces)
        case .contains:
            let trimmed = newRuleKeyword.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return "" }
            let escaped = NSRegularExpression.escapedPattern(for: trimmed)
            return newRuleCaseSensitive ? escaped : "(?i)\(escaped)"
        case .exactWord:
            let trimmed = newRuleKeyword.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return "" }
            let escaped = NSRegularExpression.escapedPattern(for: trimmed)
            return newRuleCaseSensitive ? "\\b\(escaped)\\b" : "(?i)\\b\(escaped)\\b"
        case .prefix:
            let trimmed = newRuleKeyword.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return "" }
            let escaped = NSRegularExpression.escapedPattern(for: trimmed)
            return newRuleCaseSensitive ? "^\\s*\(escaped)" : "(?i)^\\s*\(escaped)"
        case .suffix:
            let trimmed = newRuleKeyword.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return "" }
            let escaped = NSRegularExpression.escapedPattern(for: trimmed)
            return newRuleCaseSensitive ? "\(escaped)\\s*$" : "(?i)\(escaped)\\s*$"
        }
    }

    private var isSaveDisabled: Bool {
        let name = newRuleName.trimmingCharacters(in: .whitespaces)
        if name.isEmpty { return true }
        let pattern = generatedPattern
        if pattern.isEmpty { return true }
        return (try? Regex(pattern)) == nil
    }

    private func applyPreset(_ preset: (name: String, keyword: String, severity: LogRule.Severity)) {
        newRuleKeyword = preset.keyword
        if newRuleName.isEmpty {
            newRuleName = preset.name
        }
        newRuleSeverity = preset.severity
        newRuleMatchType = .contains
    }

    private func resetAddRuleForm() {
        showingAddRule = false
        newRuleName = ""
        newRulePattern = ""
        newRuleKeyword = ""
        newRuleMatchType = .contains
        newRuleCaseSensitive = false
    }

    private func saveNewRule() {
        let trimmedName = newRuleName.trimmingCharacters(in: .whitespaces)
        let pattern = generatedPattern
        guard !trimmedName.isEmpty, !pattern.isEmpty else { return }
        alertViewModel.addRule(name: trimmedName, pattern: pattern, severity: newRuleSeverity)
        resetAddRuleForm()
    }

    private var addRuleForm: some View {
        VStack(alignment: .leading, spacing: LayoutTokens.space6) {
            // Rule Name & Severity
            HStack(spacing: LayoutTokens.space4) {
                TextField(l10n("settings.rule_name_placeholder"), text: $newRuleName)
                    .textFieldStyle(.roundedBorder)
                    .font(.appCaption)

                Picker("", selection: $newRuleSeverity) {
                    ForEach(LogRule.Severity.allCases, id: \.self) { sev in
                        Text(sev.displayName).tag(sev)
                    }
                }
                .frame(width: 85)
            }

            // Presets row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    Text(l10n("settings.rule_presets") + ":")
                        .font(.system(size: 9))
                        .foregroundStyle(ColorTokens.tertiaryLabel(isDark: isDark))

                    ForEach(Self.rulePresets, id: \.name) { preset in
                        Button {
                            applyPreset(preset)
                        } label: {
                            Text(preset.name)
                                .font(.system(size: 9))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule().fill(ColorTokens.controlFill(isDark: isDark))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Match type picker
            HStack(spacing: LayoutTokens.space4) {
                Text(l10n("settings.rule_match_mode") + ":")
                    .font(.system(size: 10))
                    .foregroundStyle(ColorTokens.secondaryLabel(isDark: isDark))

                Picker("", selection: $newRuleMatchType) {
                    ForEach(RuleMatchType.allCases) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .font(.appCaption)
                .pickerStyle(.segmented)
            }

            // Input: Keyword or Regex
            if newRuleMatchType == .regex {
                TextField(l10n("settings.rule_pattern_placeholder"), text: $newRulePattern)
                    .textFieldStyle(.roundedBorder)
                    .font(.appCaption)
            } else {
                HStack(spacing: LayoutTokens.space6) {
                    TextField(l10n("settings.rule_keyword_placeholder"), text: $newRuleKeyword)
                        .textFieldStyle(.roundedBorder)
                        .font(.appCaption)

                    Toggle(isOn: $newRuleCaseSensitive) {
                        Text(l10n("settings.rule_case_sensitive"))
                            .font(.system(size: 9))
                    }
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                }
            }

            // Live pattern preview
            if !generatedPattern.isEmpty {
                HStack(spacing: 4) {
                    Text(l10n("settings.rule_preview") + ":")
                        .font(.system(size: 9))
                        .foregroundStyle(ColorTokens.tertiaryLabel(isDark: isDark))
                    Text(generatedPattern)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(ColorTokens.secondaryLabel(isDark: isDark))
                        .lineLimit(1)
                }
            }

            // Actions: Cancel & Save
            HStack {
                Button(l10n("action.cancel")) {
                    resetAddRuleForm()
                }
                .font(.appCaption)
                .buttonStyle(.bordered)
                .controlSize(.mini)

                Spacer()

                Button(l10n("action.save_rule")) {
                    saveNewRule()
                }
                .font(.appCaption)
                .buttonStyle(.borderedProminent)
                .controlSize(.mini)
                .disabled(isSaveDisabled)
            }
        }
        .padding(LayoutTokens.space6)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(ColorTokens.controlFill(isDark: isDark))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(ColorTokens.controlBorder(isDark: isDark), lineWidth: LayoutTokens.stroke)
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
