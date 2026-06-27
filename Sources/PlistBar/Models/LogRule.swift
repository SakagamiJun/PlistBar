import Foundation

struct LogRule: Identifiable, Hashable, Codable, Sendable {
    enum Severity: String, Codable, Sendable {
        case warning = "Warning"
        case error = "Error"
    }

    let id: UUID
    var name: String
    var pattern: String
    var severity: Severity
    var isEnabled: Bool

    init(
        id: UUID = UUID(),
        name: String,
        pattern: String,
        severity: Severity,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.pattern = pattern
        self.severity = severity
        self.isEnabled = isEnabled
    }
}

struct AlertItem: Identifiable, Hashable, Sendable {
    let id: UUID
    let timestamp: Date
    let jobLabel: String
    let line: String
    let matchedRule: LogRule
    var isRead: Bool

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        jobLabel: String,
        line: String,
        matchedRule: LogRule,
        isRead: Bool = false
    ) {
        self.id = id
        self.timestamp = timestamp
        self.jobLabel = jobLabel
        self.line = line
        self.matchedRule = matchedRule
        self.isRead = isRead
    }
}
