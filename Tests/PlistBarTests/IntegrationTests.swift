import Foundation
import Testing
@testable import PlistBar

@Suite("Integration Tests")
struct IntegrationTests {
    @Test("Template → writePlist → readPlist → from roundtrip")
    func plistWriteReadRoundtrip() throws {
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("PlistBarTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmpDir) }

        let plistURL = tmpDir.appendingPathComponent("com.test.integration.plist")

        // Create from template
        let draft = LaunchPlistDraft.basicAgent(label: "com.test.integration")
        let dict = try draft.toDictionary()

        // Write
        try PlistEditorService.writePlist(dictionary: dict, to: plistURL)
        #expect(FileManager.default.fileExists(atPath: plistURL.path))

        // Read back
        let readDict = try PlistEditorService.readPlist(at: plistURL)
        #expect(readDict["Label"] as? String == "com.test.integration")
        #expect(readDict["RunAtLoad"] as? Bool == true)

        // Parse back into draft
        let reloaded = LaunchPlistDraft.from(dictionary: readDict)
        #expect(reloaded.label == "com.test.integration")
        #expect(reloaded.runAtLoad == true)
    }
}
