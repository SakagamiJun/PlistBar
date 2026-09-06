import Foundation

/// Provides dynamic application versioning derived from Bundle Info.plist or git release tags.
public enum AppVersion: Sendable {
    /// Semver string without leading 'v', e.g. "1.0.0"
    public static var rawVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           !version.isEmpty {
            return version
        }
        if let path = Bundle.main.path(forResource: "version", ofType: "txt"),
           let text = try? String(contentsOfFile: path, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines),
           !text.isEmpty {
            return text
        }
        return "1.0.0"
    }

    /// Formatted version with 'v' prefix, e.g. "v1.0.0"
    public static var current: String {
        "v\(rawVersion)"
    }

    /// Build number or commit counter string
    public static var buildNumber: String {
        if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String,
           !build.isEmpty {
            return build
        }
        return "1"
    }
}
