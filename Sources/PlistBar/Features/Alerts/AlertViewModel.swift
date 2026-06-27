import Foundation

@MainActor @Observable
final class AlertViewModel {
    var alerts: [AlertItem] = []
    var rules: [LogRule] = RuleEngineService.defaultRules()

    var unreadCount: Int { alerts.filter { !$0.isRead }.count }
    var hasUnread: Bool { unreadCount > 0 }

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

        // Keep max 100 alerts
        if alerts.count > 100 {
            alerts = Array(alerts.prefix(100))
        }

        // Only send notifications for warning+ severity
        if matchedRule.severity != .info {
            NotificationService.send(
                title: "[\(matchedRule.severity.rawValue)] \(jobLabel)",
                body: String(line.prefix(200)),
                severity: matchedRule.severity
            )
        }
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
    }

    func clear() {
        alerts.removeAll()
    }
}
