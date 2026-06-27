import Foundation
import Testing
@testable import PlistBar

@Suite("LaunchService Model Tests")
struct ModelTests {
    @Test("LaunchServiceScope.directoryURL returns correct paths")
    func directoryURL() {
        let userURL = LaunchServiceScope.userAgents.directoryURL
        #expect(userURL.path.hasSuffix("Library/LaunchAgents"))
        #expect(LaunchServiceScope.globalAgents.directoryURL.path == "/Library/LaunchAgents")
        #expect(LaunchServiceScope.globalDaemons.directoryURL.path == "/Library/LaunchDaemons")
    }

    @Test("LaunchServiceScope.launchDomain returns correct domain")
    func launchDomain() {
        let uid = getuid()
        #expect(LaunchServiceScope.userAgents.launchDomain == "gui/\(uid)")
        #expect(LaunchServiceScope.globalAgents.launchDomain == "gui/\(uid)")
        #expect(LaunchServiceScope.globalDaemons.launchDomain == "system")
    }

    @Test("LaunchServiceScope.kind returns correct kind")
    func scopeKind() {
        #expect(LaunchServiceScope.userAgents.kind == .agent)
        #expect(LaunchServiceScope.globalAgents.kind == .agent)
        #expect(LaunchServiceScope.globalDaemons.kind == .daemon)
    }

    @Test("CommandResult.isSuccess logic")
    func commandResultIsSuccess() {
        let success = CommandResult(exitCode: 0, stdout: "ok", stderr: "")
        #expect(success.isSuccess)

        let failure = CommandResult(exitCode: 1, stdout: "", stderr: "error")
        #expect(!failure.isSuccess)
    }

    @Test("LaunchService equality and hash")
    func launchServiceEquality() {
        let url = URL(fileURLWithPath: "/tmp/test.plist")
        let a = LaunchService(
            plistURL: url, scope: .userAgents, label: "test",
            kind: .agent, enabled: true, runtimeStatus: .running,
            pid: 100, plistDictionary: [:]
        )
        let b = LaunchService(
            plistURL: url, scope: .userAgents, label: "test",
            kind: .agent, enabled: true, runtimeStatus: .running,
            pid: 100, plistDictionary: [:]
        )
        #expect(a == b)

        var hasherA = Hasher()
        a.hash(into: &hasherA)
        let hashA = hasherA.finalize()

        var hasherB = Hasher()
        b.hash(into: &hasherB)
        let hashB = hasherB.finalize()

        #expect(hashA == hashB)
    }
}
