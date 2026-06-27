import Foundation
import Testing
@testable import PlistBar

@Suite("Log Integration Tests")
struct LogIntegrationTests {
    @Test("loadLogsSplit reads from temp file and RuleEngine matches")
    func logsWithRuleEngine() throws {
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("PlistBarLogTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmpDir) }

        // Write test log content
        let logFile = tmpDir.appendingPathComponent("stdout.log")
        let logContent = "INFO: started\nerror: something failed\nWARNING: disk almost full\n"
        try logContent.write(to: logFile, atomically: true, encoding: .utf8)

        // Create a LaunchService pointing to the temp log file
        let plistURL = tmpDir.appendingPathComponent("com.test.log.plist")
        let plistDict: [String: Any] = [
            "Label": "com.test.log",
            "Program": "/usr/bin/true",
            "StandardOutPath": logFile.path,
        ]
        let service = LaunchService(
            plistURL: plistURL,
            scope: .userAgents,
            label: "com.test.log",
            kind: .agent,
            enabled: true,
            runtimeStatus: .running,
            pid: 123,
            plistDictionary: plistDict
        )

        // loadLogsSplit should return the file content
        let result = LaunchctlService.loadLogsSplit(service: service)
        #expect(result.stdout.contains("error: something failed"))
        #expect(result.stdout.contains("WARNING: disk almost full"))

        // RuleEngineService should match the error line
        let rules = RuleEngineService.defaultRules()
        let matched = RuleEngineService.evaluate(line: "error: something failed", against: rules)
        #expect(!matched.isEmpty)
        #expect(matched.contains { $0.name == "Error" })

        // RuleEngine should not match info-only line
        let infoMatched = RuleEngineService.evaluate(line: "INFO: started", against: rules)
        #expect(infoMatched.isEmpty)
    }
}
