import Foundation
import Testing
@testable import PlistBar

@Suite("PlistEditor Tests")
struct PlistEditorTests {
    @Test("LaunchPlistDraft.from parses StartInterval")
    func parseStartInterval() {
        let dict: [String: Any] = [
            "Label": "com.test.agent",
            "StartInterval": 600,
        ]
        let draft = LaunchPlistDraft.from(dictionary: dict)
        #expect(draft.hasSchedule)
        #expect(draft.scheduleMode == .interval)
        #expect(draft.intervalSeconds == 600)
        #expect(draft.label == "com.test.agent")
    }

    @Test("LaunchPlistDraft.from parses StartCalendarInterval dict")
    func parseCalendarDict() {
        let dict: [String: Any] = [
            "Label": "com.test.agent",
            "StartCalendarInterval": ["Hour": 9, "Minute": 30],
        ]
        let draft = LaunchPlistDraft.from(dictionary: dict)
        #expect(draft.hasSchedule)
        #expect(draft.scheduleMode == .calendar)
        #expect(draft.calendarEntries.count == 1)
        #expect(draft.calendarEntries[0].hour == 9)
        #expect(draft.calendarEntries[0].minute == 30)
    }

    @Test("LaunchPlistDraft.from parses StartCalendarInterval array")
    func parseCalendarArray() {
        let dict: [String: Any] = [
            "Label": "com.test.agent",
            "StartCalendarInterval": [
                ["Hour": 9, "Minute": 0],
                ["Hour": 17, "Minute": 0],
            ],
        ]
        let draft = LaunchPlistDraft.from(dictionary: dict)
        #expect(draft.hasSchedule)
        #expect(draft.scheduleMode == .calendar)
        #expect(draft.calendarEntries.count == 2)
    }

    @Test("LaunchPlistDraft.toDictionary roundtrip")
    func roundtrip() throws {
        var draft = LaunchPlistDraft()
        draft.label = "com.test.roundtrip"
        draft.program = "/usr/bin/echo"
        draft.runAtLoad = true
        draft.keepAlive = false
        draft.hasSchedule = true
        draft.scheduleMode = .interval
        draft.intervalSeconds = 300

        let dict = try draft.toDictionary()
        #expect(dict["Label"] as? String == "com.test.roundtrip")
        #expect(dict["Program"] as? String == "/usr/bin/echo")
        #expect(dict["RunAtLoad"] as? Bool == true)
        #expect(dict["StartInterval"] as? Int == 300)

        let reloaded = LaunchPlistDraft.from(dictionary: dict)
        #expect(reloaded.label == "com.test.roundtrip")
        #expect(reloaded.hasSchedule)
        #expect(reloaded.intervalSeconds == 300)
    }

    @Test("PlistEditorService.validate — no Label throws")
    func validateNoLabel() {
        let dict: [String: Any] = ["Program": "/usr/bin/echo"]
        #expect(throws: (any Error).self) {
            try PlistEditorService.validate(dictionary: dict)
        }
    }

    @Test("PlistEditorService.validate — no Program and no ProgramArguments throws")
    func validateNoProgram() {
        let dict: [String: Any] = ["Label": "com.test"]
        #expect(throws: (any Error).self) {
            try PlistEditorService.validate(dictionary: dict)
        }
    }

    @Test("PlistEditorService.xmlString and fromRawXML roundtrip")
    func xmlRoundtrip() throws {
        let dict: [String: Any] = [
            "Label": "com.test.xml",
            "Program": "/usr/bin/true",
        ]
        let xml = try PlistEditorService.xmlString(from: dict)
        #expect(xml.contains("com.test.xml"))

        let parsed = try PlistEditorService.dictionary(fromRawXML: xml)
        #expect(parsed["Label"] as? String == "com.test.xml")
        #expect(parsed["Program"] as? String == "/usr/bin/true")
    }

    @Test("Template basicAgent generates valid draft")
    func templateBasicAgent() throws {
        let draft = LaunchPlistDraft.basicAgent(label: "com.test.basic")
        let dict = try draft.toDictionary()
        try PlistEditorService.validate(dictionary: dict)
        #expect(dict["Label"] as? String == "com.test.basic")
        #expect(dict["RunAtLoad"] as? Bool == true)
    }

    @Test("Template intervalTask generates valid draft")
    func templateIntervalTask() throws {
        let draft = LaunchPlistDraft.intervalTask(label: "com.test.interval", interval: 120)
        let dict = try draft.toDictionary()
        try PlistEditorService.validate(dictionary: dict)
        #expect(dict["StartInterval"] as? Int == 120)
    }

    @Test("Template calendarTask generates valid draft")
    func templateCalendarTask() throws {
        let draft = LaunchPlistDraft.calendarTask(label: "com.test.calendar")
        let dict = try draft.toDictionary()
        try PlistEditorService.validate(dictionary: dict)
    }

    @Test("Template watchPathTask generates valid draft")
    func templateWatchPath() throws {
        let draft = LaunchPlistDraft.watchPathTask(label: "com.test.watch")
        let dict = try draft.toDictionary()
        try PlistEditorService.validate(dictionary: dict)
    }

    @Test("CalendarEntry summary format")
    func calendarEntrySummary() {
        let entry1 = LaunchPlistDraft.CalendarEntry(minute: 15, hour: 14)
        #expect(entry1.summary == "14:15")

        let entry2 = LaunchPlistDraft.CalendarEntry(minute: 0, hour: 9, weekday: 2)
        #expect(entry2.summary.contains("Mon"))
        #expect(entry2.summary.contains("09:00"))
    }

    @Test("LaunchPlistDraft environmentVariables and watchPaths roundtrip")
    func advancedDraftProperties() throws {
        var draft = LaunchPlistDraft.blank()
        draft.label = "com.test.advanced"
        draft.program = "/bin/sh"
        draft.environmentVariablesText = "FOO=bar\nBAZ=qux"
        draft.watchPathsText = "/tmp/dir1\n/tmp/dir2"

        let dict = try draft.toDictionary()
        let env = dict["EnvironmentVariables"] as? [String: String]
        #expect(env?["FOO"] == "bar")
        #expect(env?["BAZ"] == "qux")

        let watch = dict["WatchPaths"] as? [String]
        #expect(watch?.contains("/tmp/dir1") == true)
        #expect(watch?.contains("/tmp/dir2") == true)
    }
}
