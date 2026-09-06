import Foundation

@MainActor @Observable
final class EditorViewModel {
    var draft: LaunchPlistDraft
    var isRawXMLMode: Bool = false
    var rawXMLText: String = ""
    var errorMessage: String?

    init(draft: LaunchPlistDraft = .blank()) {
        self.draft = draft
    }

    func loadFromService(_ service: LaunchService) {
        draft = LaunchPlistDraft.from(dictionary: service.plistDictionary)
        do {
            rawXMLText = try PlistEditorService.xmlString(from: service.plistDictionary)
        } catch {
            rawXMLText = "<!-- Failed to generate XML: \(error.localizedDescription) -->"
        }
        errorMessage = nil
    }

    @discardableResult
    func save(to service: LaunchService) -> Bool {
        do {
            let finalDict: [String: Any]
            if isRawXMLMode {
                finalDict = try PlistEditorService.dictionary(fromRawXML: rawXMLText)
            } else {
                finalDict = try draft.toDictionary()
            }

            try PlistEditorService.validate(dictionary: finalDict)
            try PlistEditorService.writePlist(dictionary: finalDict, to: service.plistURL)
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func createNewUserAgent(filename: String? = nil) throws -> URL {
        let rawName: String
        if let filename, !filename.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            rawName = filename.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            rawName = draft.label.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard !rawName.isEmpty else {
            let error = CommandError.executionFailed("Label is required to name the plist file.")
            errorMessage = error.localizedDescription
            throw error
        }

        let finalName = rawName.hasSuffix(".plist") ? rawName : "\(rawName).plist"
        let url = LaunchServiceScope.userAgents.directoryURL.appendingPathComponent(finalName)

        let dict: [String: Any]
        if isRawXMLMode {
            dict = try PlistEditorService.dictionary(fromRawXML: rawXMLText)
        } else {
            dict = try draft.toDictionary()
        }

        try PlistEditorService.validate(dictionary: dict)
        try FileManager.default.createDirectory(
            at: LaunchServiceScope.userAgents.directoryURL,
            withIntermediateDirectories: true
        )
        try PlistEditorService.writePlist(dictionary: dict, to: url)
        errorMessage = nil
        return url
    }
}
