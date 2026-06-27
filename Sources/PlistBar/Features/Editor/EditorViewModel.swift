import Foundation

@MainActor @Observable
final class EditorViewModel {
    var draft: LaunchPlistDraft
    var isRawXMLMode: Bool = false
    var rawXMLText: String = ""
    var errorMessage: String?

    init(draft: LaunchPlistDraft) {
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

    func save(to service: LaunchService) {
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
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createNewUserAgent(filename: String) throws -> URL {
        let trimmed = filename.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw CommandError.executionFailed("Filename is required.")
        }

        let finalName = trimmed.hasSuffix(".plist") ? trimmed : "\(trimmed).plist"
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
