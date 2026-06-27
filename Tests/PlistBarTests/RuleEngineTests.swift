import Foundation
import Testing
@testable import PlistBar

@Suite("RuleEngine Tests")
struct RuleEngineTests {
    @Test("evaluate matches 'error' against Error rule")
    func matchesError() {
        let rules = RuleEngineService.defaultRules()
        let matched = RuleEngineService.evaluate(line: "error: something went wrong", against: rules)
        #expect(matched.contains { $0.name == "Error" })
    }

    @Test("evaluate does not match 'INFO: started'")
    func noMatchForInfo() {
        let rules = RuleEngineService.defaultRules()
        let matched = RuleEngineService.evaluate(line: "INFO: started successfully", against: rules)
        #expect(matched.isEmpty)
    }

    @Test("disabled rules do not match")
    func disabledRulesIgnored() {
        var rules = RuleEngineService.defaultRules()
        if let index = rules.firstIndex(where: { $0.name == "Error" }) {
            rules[index].isEnabled = false
        }
        let matched = RuleEngineService.evaluate(line: "error: something failed", against: rules)
        #expect(!matched.contains { $0.name == "Error" })
    }

    @Test("case insensitive matching")
    func caseInsensitive() {
        let rules = RuleEngineService.defaultRules()
        let matched = RuleEngineService.evaluate(line: "FATAL: crash detected", against: rules)
        #expect(matched.contains { $0.name == "Fatal" })
        #expect(matched.contains { $0.name == "Crash" })
    }

    @Test("defaultRules is non-empty")
    func defaultRulesNonEmpty() {
        let rules = RuleEngineService.defaultRules()
        #expect(!rules.isEmpty)
    }

    @Test("LogRule Codable roundtrip")
    func logRuleCodable() throws {
        let rule = LogRule(name: "Test", pattern: "test", severity: .error)
        let data = try JSONEncoder().encode(rule)
        let decoded = try JSONDecoder().decode(LogRule.self, from: data)
        #expect(decoded.name == "Test")
        #expect(decoded.pattern == "test")
        #expect(decoded.severity == .error)
    }
}
