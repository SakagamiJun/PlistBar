import Foundation

struct LaunchPlistDraft {
    enum ScheduleMode: String, CaseIterable, Identifiable, Sendable {
        case interval = "Interval"
        case calendar = "Calendar"

        var id: String { rawValue }
    }

    struct CalendarEntry: Identifiable, Hashable, Sendable {
        let id: UUID
        var minute: Int?
        var hour: Int?
        var day: Int?
        var weekday: Int?
        var month: Int?

        init(
            id: UUID = UUID(),
            minute: Int? = nil,
            hour: Int? = nil,
            day: Int? = nil,
            weekday: Int? = nil,
            month: Int? = nil
        ) {
            self.id = id
            self.minute = minute
            self.hour = hour
            self.day = day
            self.weekday = weekday
            self.month = month
        }

        init(dictionary: [String: Any]) {
            id = UUID()
            minute = Self.readInt(dictionary["Minute"])
            hour = Self.readInt(dictionary["Hour"])
            day = Self.readInt(dictionary["Day"])
            weekday = Self.readInt(dictionary["Weekday"])
            month = Self.readInt(dictionary["Month"])
        }

        var dictionaryValue: [String: Int] {
            var dict: [String: Int] = [:]
            if let minute { dict["Minute"] = minute }
            if let hour { dict["Hour"] = hour }
            if let day { dict["Day"] = day }
            if let weekday { dict["Weekday"] = weekday }
            if let month { dict["Month"] = month }
            return dict
        }

        private static func readInt(_ value: Any?) -> Int? {
            switch value {
            case let int as Int:
                return int
            case let number as NSNumber:
                return number.intValue
            case let string as String:
                return Int(string.trimmingCharacters(in: .whitespacesAndNewlines))
            default:
                return nil
            }
        }
    }

    private static let scheduleIntervalKey = "StartInterval"
    private static let scheduleCalendarKey = "StartCalendarInterval"

    var fields: [String: Any] = [:]
    var scheduleMode: ScheduleMode = .interval
    var intervalSeconds: Int = 3600
    var calendarEntries: [CalendarEntry] = []
    var hasSchedule: Bool = false

    static func from(dictionary: [String: Any]) -> LaunchPlistDraft {
        var draft = LaunchPlistDraft()
        draft.fields = dictionary

        if let interval = Self.asInt(dictionary[Self.scheduleIntervalKey]) {
            draft.hasSchedule = true
            draft.scheduleMode = .interval
            draft.intervalSeconds = max(interval, 1)
            draft.fields.removeValue(forKey: Self.scheduleIntervalKey)
            draft.fields.removeValue(forKey: Self.scheduleCalendarKey)
        } else if let calendarRaw = dictionary[Self.scheduleCalendarKey] {
            draft.hasSchedule = true
            draft.scheduleMode = .calendar
            draft.calendarEntries = Self.parseCalendarEntries(calendarRaw)
            if draft.calendarEntries.isEmpty {
                draft.calendarEntries = [CalendarEntry()]
            }
            draft.fields.removeValue(forKey: Self.scheduleIntervalKey)
            draft.fields.removeValue(forKey: Self.scheduleCalendarKey)
        }

        return draft
    }

    func toDictionary() throws -> [String: Any] {
        var dict = fields

        for (key, value) in dict {
            if let string = value as? String {
                let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty {
                    dict.removeValue(forKey: key)
                } else {
                    dict[key] = trimmed
                }
            }
        }

        dict.removeValue(forKey: Self.scheduleIntervalKey)
        dict.removeValue(forKey: Self.scheduleCalendarKey)

        if hasSchedule {
            switch scheduleMode {
            case .interval:
                dict[Self.scheduleIntervalKey] = max(intervalSeconds, 1)
            case .calendar:
                let payload = calendarEntries
                    .map(\.dictionaryValue)
                    .filter { !$0.isEmpty }
                if payload.count == 1, let first = payload.first {
                    dict[Self.scheduleCalendarKey] = first
                } else if !payload.isEmpty {
                    dict[Self.scheduleCalendarKey] = payload
                }
            }
        }

        return dict
    }

    mutating func addField(_ key: String, defaultValue: Any) {
        if key == Self.scheduleIntervalKey {
            hasSchedule = true
            scheduleMode = .interval
            if intervalSeconds < 1 {
                intervalSeconds = 3600
            }
            return
        }
        if key == Self.scheduleCalendarKey {
            hasSchedule = true
            scheduleMode = .calendar
            if calendarEntries.isEmpty {
                calendarEntries = [CalendarEntry(minute: 0, hour: 9)]
            }
            return
        }
        fields[key] = defaultValue
    }

    mutating func removeField(_ key: String) {
        if key == Self.scheduleIntervalKey || key == Self.scheduleCalendarKey {
            hasSchedule = false
            return
        }
        fields.removeValue(forKey: key)
    }

    func isFieldConfigured(_ key: String) -> Bool {
        if key == Self.scheduleIntervalKey || key == Self.scheduleCalendarKey {
            return hasSchedule
        }
        return fields[key] != nil
    }

    func stringValue(for key: String) -> String {
        fields[key] as? String ?? ""
    }

    mutating func setStringValue(for key: String, value: String) {
        fields[key] = value
    }

    func boolValue(for key: String, default defaultValue: Bool = false) -> Bool {
        switch fields[key] {
        case let bool as Bool:
            return bool
        case let int as Int:
            return int != 0
        case let string as String:
            return (string as NSString).boolValue
        default:
            return defaultValue
        }
    }

    mutating func setBoolValue(for key: String, value: Bool) {
        fields[key] = value
    }

    func intValue(for key: String, default defaultValue: Int = 0) -> Int {
        Self.asInt(fields[key]) ?? defaultValue
    }

    mutating func setIntValue(for key: String, value: Int) {
        fields[key] = value
    }

    func stringArrayValue(for key: String) -> [String] {
        if let values = fields[key] as? [String] {
            return values
        }
        if let values = fields[key] as? [Any] {
            return values.compactMap { $0 as? String }
        }
        return []
    }

    mutating func setStringArrayValue(for key: String, values: [String]) {
        let trimmed = values
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        fields[key] = trimmed
    }

    private static func parseCalendarEntries(_ value: Any) -> [CalendarEntry] {
        if let dict = value as? [String: Any] {
            return [CalendarEntry(dictionary: dict)]
        }
        if let list = value as? [[String: Any]] {
            return list.map(CalendarEntry.init(dictionary:))
        }
        if let list = value as? [Any] {
            return list.compactMap { item in
                guard let dict = item as? [String: Any] else { return nil }
                return CalendarEntry(dictionary: dict)
            }
        }
        return []
    }

    private static func asInt(_ value: Any?) -> Int? {
        switch value {
        case let int as Int:
            return int
        case let number as NSNumber:
            return number.intValue
        case let string as String:
            return Int(string.trimmingCharacters(in: .whitespacesAndNewlines))
        default:
            return nil
        }
    }

    // MARK: - Convenience properties

    var label: String {
        get { stringValue(for: "Label") }
        set { setStringValue(for: "Label", value: newValue) }
    }

    var program: String {
        get { stringValue(for: "Program") }
        set { setStringValue(for: "Program", value: newValue) }
    }

    var programArgumentsText: String {
        get { stringArrayValue(for: "ProgramArguments").joined(separator: "\n") }
        set {
            let values = newValue
                .split(separator: "\n")
                .map(String.init)
            setStringArrayValue(for: "ProgramArguments", values: values)
        }
    }

    var runAtLoad: Bool {
        get { boolValue(for: "RunAtLoad") }
        set { setBoolValue(for: "RunAtLoad", value: newValue) }
    }

    var keepAlive: Bool {
        get { boolValue(for: "KeepAlive") }
        set { setBoolValue(for: "KeepAlive", value: newValue) }
    }

    var standardOutPath: String {
        get { stringValue(for: "StandardOutPath") }
        set { setStringValue(for: "StandardOutPath", value: newValue) }
    }

    var standardErrorPath: String {
        get { stringValue(for: "StandardErrorPath") }
        set { setStringValue(for: "StandardErrorPath", value: newValue) }
    }

    var workingDirectory: String {
        get { stringValue(for: "WorkingDirectory") }
        set { setStringValue(for: "WorkingDirectory", value: newValue) }
    }
}

// MARK: - Templates

extension LaunchPlistDraft {
    static func basicAgent(label: String) -> Self {
        var draft = LaunchPlistDraft()
        draft.label = label
        draft.program = "/usr/local/bin/myapp"
        draft.runAtLoad = true
        return draft
    }

    static func intervalTask(label: String, interval: Int = 3600) -> Self {
        var draft = LaunchPlistDraft()
        draft.label = label
        draft.program = "/usr/local/bin/myapp"
        draft.hasSchedule = true
        draft.scheduleMode = .interval
        draft.intervalSeconds = interval
        return draft
    }

    static func calendarTask(label: String) -> Self {
        var draft = LaunchPlistDraft()
        draft.label = label
        draft.program = "/usr/local/bin/myapp"
        draft.hasSchedule = true
        draft.scheduleMode = .calendar
        draft.calendarEntries = [CalendarEntry(minute: 0, hour: 9)]
        return draft
    }

    static func watchPathTask(label: String) -> Self {
        var draft = LaunchPlistDraft()
        draft.label = label
        draft.program = "/usr/local/bin/myapp"
        draft.fields["WatchPaths"] = ["/tmp/watch"]
        return draft
    }

    static func blank() -> Self {
        LaunchPlistDraft()
    }
}
