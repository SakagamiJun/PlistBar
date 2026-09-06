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

    @Test("escaped pattern safely matches special characters without syntax errors")
    func escapedPatternMatchesSafely() {
        let keyword = "[FATAL ERROR] (code: 404)"
        let escaped = NSRegularExpression.escapedPattern(for: keyword)
        let pattern = "(?i)\(escaped)"
        let rule = LogRule(name: "SpecialCharRule", pattern: pattern, severity: .error)

        let matchingLine = "2026-09-06 [fatal error] (code: 404) happened"
        let nonMatchingLine = "2026-09-06 normal message"

        let matched1 = RuleEngineService.evaluate(line: matchingLine, against: [rule])
        #expect(matched1.count == 1)

        let matched2 = RuleEngineService.evaluate(line: nonMatchingLine, against: [rule])
        #expect(matched2.isEmpty)
    }

    @Test("keyword prefix and suffix match modes")
    func prefixAndSuffixMatchModes() {
        let prefixPattern = "(?i)^\\s*" + NSRegularExpression.escapedPattern(for: "crash")
        let prefixRule = LogRule(name: "PrefixRule", pattern: prefixPattern, severity: .error)

        let suffixPattern = "(?i)" + NSRegularExpression.escapedPattern(for: "failed") + "\\s*$"
        let suffixRule = LogRule(name: "SuffixRule", pattern: suffixPattern, severity: .warning)

        #expect(!RuleEngineService.evaluate(line: "  crash detected", against: [prefixRule]).isEmpty)
        #expect(RuleEngineService.evaluate(line: "system crash detected", against: [prefixRule]).isEmpty)

        #expect(!RuleEngineService.evaluate(line: "job execution failed  ", against: [suffixRule]).isEmpty)
        #expect(RuleEngineService.evaluate(line: "failed to start", against: [suffixRule]).isEmpty)
    }

    @Test("AppVersion provides valid version strings")
    func appVersionValidation() {
        #expect(!AppVersion.rawVersion.isEmpty)
        #expect(AppVersion.current.hasPrefix("v"))
        #expect(!AppVersion.buildNumber.isEmpty)
    }
}
