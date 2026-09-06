import Foundation

@MainActor @Observable
final class AlertViewModel {
    private static let rulesStorageKey = "plistbar.log_rules"

    var alerts: [AlertItem] = []
    var rules: [LogRule] = []

    var onAlertStateChanged: (@MainActor () -> Void)?

    init() {
        self.rules = Self.loadRules()
    }

    var unreadCount: Int {
        alerts.filter { !$0.isRead }.count
    }

    var hasUnread: Bool {
        unreadCount > 0
    }

    var hasError: Bool {
        alerts.contains { !$0.isRead && $0.severity == .error }
    }

    var hasWarning: Bool {
        alerts.contains { !$0.isRead && $0.severity == .warning }
    }

    func addAlert(from matchedRule: LogRule, line: String, jobLabel: String) {
        let alert = AlertItem(
            jobLabel: jobLabel,
            ruleName: matchedRule.name,
            matchedLine: line,
            severity: matchedRule.severity
        )
        alerts.insert(alert, at: 0)

        // Strict 100-alert memory limit: truncate older entries
        if alerts.count > 100 {
            alerts = Array(alerts.prefix(100))
        }

        // Only send system notification for warning / error severity (design.md §5.4.3)
        if matchedRule.severity != .info {
            NotificationService.send(
                title: "[\(matchedRule.severity.rawValue)] \(jobLabel)",
                body: String(line.prefix(200)),
                severity: matchedRule.severity
            )
        }

        onAlertStateChanged?()
    }

    func processLogLine(_ line: String, jobLabel: String) {
        let matched = RuleEngineService.evaluate(line: line, against: rules)
        for rule in matched {
            addAlert(from: rule, line: line, jobLabel: jobLabel)
        }
    }

    func markAllRead() {
        for index in alerts.indices {
            alerts[index].isRead = true
        }
        onAlertStateChanged?()
    }

    func clear() {
        alerts.removeAll()
        onAlertStateChanged?()
    }

    // MARK: - Rule Management

    func addRule(name: String, pattern: String, severity: LogRule.Severity) {
        let rule = LogRule(name: name, pattern: pattern, severity: severity)
        rules.append(rule)
        saveRules()
    }

    func toggleRule(id: UUID) {
        if let idx = rules.firstIndex(where: { $0.id == id }) {
            rules[idx].isEnabled.toggle()
            saveRules()
        }
    }

    func deleteRule(id: UUID) {
        rules.removeAll { $0.id == id }
        saveRules()
    }

    func resetRulesToDefault() {
        rules = RuleEngineService.defaultRules()
        saveRules()
    }

    private func saveRules() {
        if let data = try? JSONEncoder().encode(rules) {
            UserDefaults.standard.set(data, forKey: Self.rulesStorageKey)
        }
    }

    private static func loadRules() -> [LogRule] {
        if let data = UserDefaults.standard.data(forKey: rulesStorageKey),
           let decoded = try? JSONDecoder().decode([LogRule].self, from: data),
           !decoded.isEmpty {
            return decoded
        }
        return RuleEngineService.defaultRules()
    }
}
