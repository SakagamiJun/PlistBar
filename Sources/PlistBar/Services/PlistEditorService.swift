import Foundation

enum PlistEditorService: Sendable {
    static func readPlist(at url: URL) throws -> [String: Any] {
        let data = try Data(contentsOf: url)
        let format = UnsafeMutablePointer<PropertyListSerialization.PropertyListFormat>.allocate(capacity: 1)
        defer { format.deallocate() }
        let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: format)
        guard let dict = plist as? [String: Any] else {
            throw CommandError.executionFailed("Plist is not a dictionary: \(url.path)")
        }
        return dict
    }

    static func writePlist(dictionary: [String: Any], to url: URL) throws {
        let data = try PropertyListSerialization.data(fromPropertyList: dictionary, format: .xml, options: 0)
        try data.write(to: url, options: .atomic)
    }

    static func xmlString(from dictionary: [String: Any]) throws -> String {
        let data = try PropertyListSerialization.data(fromPropertyList: dictionary, format: .xml, options: 0)
        guard let string = String(data: data, encoding: .utf8) else {
            throw CommandError.executionFailed("Could not convert plist to UTF-8 string")
        }
        return string
    }

    static func dictionary(fromRawXML raw: String) throws -> [String: Any] {
        let data = Data(raw.utf8)
        let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        guard let dict = plist as? [String: Any] else {
            throw CommandError.executionFailed("Raw plist is not a dictionary")
        }
        return dict
    }

    static func validate(dictionary: [String: Any]) throws {
        let label = (dictionary["Label"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if label.isEmpty {
            throw CommandError.executionFailed("Label is required.")
        }

        let program = (dictionary["Program"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let args = dictionary["ProgramArguments"] as? [String] ?? []
        if program.isEmpty && args.isEmpty {
            throw CommandError.executionFailed("Provide Program or ProgramArguments.")
        }
    }
}
