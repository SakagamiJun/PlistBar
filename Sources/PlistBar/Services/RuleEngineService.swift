import Foundation

enum RuleEngineService: Sendable {
    static func evaluate(line: String, against rules: [LogRule]) -> [LogRule] {
        rules.filter { rule in
            guard rule.isEnabled else { return false }
            guard let regex = try? Regex(rule.pattern) else { return false }
            return (try? regex.firstMatch(in: line)) != nil
        }
    }

    static func defaultRules() -> [LogRule] {
        [
            LogRule(name: "Error", pattern: "(?i)\\berror\\b", severity: .error),
            LogRule(name: "Fatal", pattern: "(?i)\\bfatal\\b", severity: .error),
            LogRule(name: "Crash", pattern: "(?i)\\bcrash\\b", severity: .error),
            LogRule(name: "Warning", pattern: "(?i)\\bwarning\\b", severity: .warning),
        ]
    }
}
