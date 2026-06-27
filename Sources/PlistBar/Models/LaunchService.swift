import Foundation
import SwiftUI

enum LaunchServiceScope: String, CaseIterable, Identifiable, Sendable {
    case userAgents = "User Agents"
    case globalAgents = "Global Agents"
    case globalDaemons = "Global Daemons"

    var id: String { rawValue }

    var displayName: LocalizedStringKey {
        LocalizedStringKey(rawValue)
    }

    var directoryURL: URL {
        switch self {
        case .userAgents:
            return FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library")
                .appendingPathComponent("LaunchAgents")
        case .globalAgents:
            return URL(fileURLWithPath: "/Library/LaunchAgents")
        case .globalDaemons:
            return URL(fileURLWithPath: "/Library/LaunchDaemons")
        }
    }

    var launchDomain: String {
        switch self {
        case .userAgents, .globalAgents:
            return "gui/\(getuid())"
        case .globalDaemons:
            return "system"
        }
    }

    var kind: LaunchServiceKind {
        switch self {
        case .globalDaemons:
            return .daemon
        case .userAgents, .globalAgents:
            return .agent
        }
    }
}

enum LaunchServiceKind: String, CaseIterable, Identifiable, Sendable {
    case agent = "Agent"
    case daemon = "Daemon"

    var id: String { rawValue }

    var displayName: LocalizedStringKey {
        LocalizedStringKey(rawValue)
    }
}

enum LaunchRuntimeStatus: String, CaseIterable, Identifiable, Sendable {
    case running = "Running"
    case loaded = "Loaded"
    case stopped = "Not Running"

    var id: String { rawValue }

    var displayName: LocalizedStringKey {
        LocalizedStringKey(rawValue)
    }
}

/// Plist dictionary values are limited to property list types (String, Int, Bool, Data, Date,
/// Array, Dictionary), all of which are value types or contain only Sendable children.
/// Marking the struct `@unchecked Sendable` avoids wrapping overhead while remaining safe.
struct LaunchService: Identifiable, Hashable, @unchecked Sendable {
    var id: String { plistURL.path }
    let plistURL: URL
    let scope: LaunchServiceScope
    var label: String
    var kind: LaunchServiceKind
    var enabled: Bool
    var runtimeStatus: LaunchRuntimeStatus
    var pid: Int?
    var plistDictionary: [String: Any]

    init(
        plistURL: URL,
        scope: LaunchServiceScope,
        label: String,
        kind: LaunchServiceKind,
        enabled: Bool,
        runtimeStatus: LaunchRuntimeStatus,
        pid: Int?,
        plistDictionary: [String: Any]
    ) {
        self.plistURL = plistURL
        self.scope = scope
        self.label = label
        self.kind = kind
        self.enabled = enabled
        self.runtimeStatus = runtimeStatus
        self.pid = pid
        self.plistDictionary = plistDictionary
    }

    static func == (lhs: LaunchService, rhs: LaunchService) -> Bool {
        lhs.plistURL == rhs.plistURL
        && lhs.runtimeStatus == rhs.runtimeStatus
        && lhs.pid == rhs.pid
        && lhs.enabled == rhs.enabled
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(plistURL)
        hasher.combine(runtimeStatus)
        hasher.combine(pid)
        hasher.combine(enabled)
    }
}

// MARK: - Convenience properties (from plistDictionary, per design.md §4.3)

extension LaunchService {
    var program: String? { plistDictionary["Program"] as? String }
    var programArguments: [String]? { plistDictionary["ProgramArguments"] as? [String] }
    var runAtLoad: Bool { plistDictionary["RunAtLoad"] as? Bool ?? false }
    var keepAlive: Bool {
        if let b = plistDictionary["KeepAlive"] as? Bool { return b }
        if plistDictionary["KeepAlive"] is [String: Any] { return true }
        return false
    }
    var standardOutPath: String? { plistDictionary["StandardOutPath"] as? String }
    var standardErrorPath: String? { plistDictionary["StandardErrorPath"] as? String }
}

// MARK: - Convenience accessors on [String: Any]

extension Dictionary where Key == String, Value == Any {
    var launchLabel: String? { self["Label"] as? String }
    var standardOutPath: String? { self["StandardOutPath"] as? String }
    var standardErrorPath: String? { self["StandardErrorPath"] as? String }
}
