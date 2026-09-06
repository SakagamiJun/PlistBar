import Foundation

enum LaunchctlService: Sendable {
    static func discoverServices() throws -> [LaunchService] {
        var services: [LaunchService] = []
        for scope in LaunchServiceScope.allCases {
            let url = scope.directoryURL
            guard let enumerator = FileManager.default.enumerator(
                at: url,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            ) else {
                continue
            }

            for case let fileURL as URL in enumerator {
                guard fileURL.pathExtension == "plist" else { continue }
                let plist: [String: Any]
                do {
                    plist = try PlistEditorService.readPlist(at: fileURL)
                } catch {
                    continue
                }

                let label = plist.launchLabel ?? fileURL.deletingPathExtension().lastPathComponent
                let kind = scope.kind
                let (status, pid) = runtimeStatus(label: label, scope: scope)
                let enabled = isEnabled(label: label, scope: scope)

                services.append(
                    LaunchService(
                        plistURL: fileURL,
                        scope: scope,
                        label: label,
                        kind: kind,
                        enabled: enabled,
                        runtimeStatus: status,
                        pid: pid,
                        plistDictionary: plist
                    )
                )
            }
        }

        return services.sorted { lhs, rhs in
            if lhs.scope == rhs.scope {
                return lhs.label.localizedCaseInsensitiveCompare(rhs.label) == .orderedAscending
            }
            return lhs.scope.rawValue < rhs.scope.rawValue
        }
    }

    static func runtimeStatus(label: String, scope: LaunchServiceScope) -> (LaunchRuntimeStatus, Int?) {
        let target = "\(scope.launchDomain)/\(label)"
        guard let result = try? CommandRunner.run("/bin/launchctl", arguments: ["print", target]), result.isSuccess else {
            return (.stopped, nil)
        }

        let output = result.stdout + "\n" + result.stderr
        if let pid = parseFirstInt(in: output, after: "pid =") {
            return (.running, pid)
        }
        return (.loaded, nil)
    }

    static func disabledLabels(for domain: String) -> Set<String> {
        guard let result = try? CommandRunner.run("/bin/launchctl", arguments: ["print-disabled", domain]), result.isSuccess else {
            return []
        }

        var disabled = Set<String>()
        let lines = result.stdout.split(separator: "\n")
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.contains("=> true") || trimmed.contains("=> disabled") else { continue }
            if let firstQuote = trimmed.firstIndex(of: "\""),
               let secondQuote = trimmed[trimmed.index(after: firstQuote)...].firstIndex(of: "\"") {
                let label = String(trimmed[trimmed.index(after: firstQuote)..<secondQuote])
                disabled.insert(label)
            } else if let arrow = trimmed.range(of: "=>") {
                let label = String(trimmed[..<arrow.lowerBound]).trimmingCharacters(in: .whitespaces)
                if !label.isEmpty {
                    disabled.insert(label)
                }
            }
        }
        return disabled
    }

    static func isEnabled(label: String, scope: LaunchServiceScope) -> Bool {
        let disabled = disabledLabels(for: scope.launchDomain)
        return !disabled.contains(label)
    }

    static func load(service: LaunchService) throws {
        let domain = service.scope.launchDomain
        let target = "\(domain)/\(service.label)"

        let _ = try? CommandRunner.run("/bin/launchctl", arguments: ["enable", target])

        let result = try CommandRunner.run("/bin/launchctl", arguments: ["bootstrap", domain, service.plistURL.path])
        if result.isSuccess { return }

        let errText = result.stderr + result.stdout
        if errText.contains("already loaded") || errText.contains("service already loaded") { return }

        let legacy = try CommandRunner.run("/bin/launchctl", arguments: ["load", "-w", service.plistURL.path])
        if legacy.isSuccess { return }

        throw CommandError.executionFailed(nonEmptyError(from: result))
    }

    static func unload(service: LaunchService) throws {
        let domain = service.scope.launchDomain
        let target = "\(domain)/\(service.label)"

        if let printResult = try? CommandRunner.run("/bin/launchctl", arguments: ["print", target]),
           !printResult.isSuccess {
            return
        }

        let result = try CommandRunner.run("/bin/launchctl", arguments: ["bootout", target])
        if result.isSuccess { return }

        let result2 = try CommandRunner.run("/bin/launchctl", arguments: ["bootout", domain, service.plistURL.path])
        if result2.isSuccess { return }

        let legacy = try CommandRunner.run("/bin/launchctl", arguments: ["unload", service.plistURL.path])
        if legacy.isSuccess { return }

        let errText = result.stderr + result.stdout
        if errText.contains("Input/output error") || result.exitCode == 5 {
            return
        }

        throw CommandError.executionFailed(nonEmptyError(from: result))
    }

    static func start(service: LaunchService) throws {
        let domain = service.scope.launchDomain
        let target = "\(domain)/\(service.label)"

        let _ = try? CommandRunner.run("/bin/launchctl", arguments: ["enable", target])
        let _ = try? CommandRunner.run("/bin/launchctl", arguments: ["bootstrap", domain, service.plistURL.path])
        let _ = try? CommandRunner.run("/bin/launchctl", arguments: ["load", "-w", service.plistURL.path])

        let result = try CommandRunner.run("/bin/launchctl", arguments: ["kickstart", "-kp", target])
        if result.isSuccess { return }

        let legacy = try CommandRunner.run("/bin/launchctl", arguments: ["start", service.label])
        if legacy.isSuccess { return }

        throw CommandError.executionFailed(nonEmptyError(from: result))
    }

    static func stop(service: LaunchService) throws {
        let domain = service.scope.launchDomain
        let keepAlive = service.plistDictionary["KeepAlive"]
        let isKeepAlive: Bool = {
            if let b = keepAlive as? Bool { return b }
            if keepAlive is [String: Any] { return true }
            return false
        }()

        if isKeepAlive {
            let result = try CommandRunner.run("/bin/launchctl", arguments: ["bootout", domain, service.plistURL.path])
            if result.isSuccess { return }
            let result2 = try CommandRunner.run("/bin/launchctl", arguments: ["bootout", "\(domain)/\(service.label)"])
            if result2.isSuccess { return }
            let legacy = try CommandRunner.run("/bin/launchctl", arguments: ["unload", service.plistURL.path])
            if legacy.isSuccess { return }
            throw CommandError.executionFailed(nonEmptyError(from: result))
        } else {
            let target = "\(domain)/\(service.label)"
            let result = try CommandRunner.run("/bin/launchctl", arguments: ["kill", "SIGTERM", target])
            if result.isSuccess { return }
            let legacy = try CommandRunner.run("/bin/launchctl", arguments: ["stop", service.label])
            if legacy.isSuccess { return }
            let errText = result.stderr + result.stdout
            if errText.contains("No such process") || errText.contains("Could not find service") {
                return
            }
            throw CommandError.executionFailed(nonEmptyError(from: result))
        }
    }

    static func enable(service: LaunchService) throws {
        let target = "\(service.scope.launchDomain)/\(service.label)"
        let result = try CommandRunner.run("/bin/launchctl", arguments: ["enable", target])
        guard result.isSuccess else {
            throw CommandError.executionFailed(nonEmptyError(from: result))
        }
    }

    static func disable(service: LaunchService) throws {
        let target = "\(service.scope.launchDomain)/\(service.label)"
        let result = try CommandRunner.run("/bin/launchctl", arguments: ["disable", target])
        guard result.isSuccess else {
            throw CommandError.executionFailed(nonEmptyError(from: result))
        }
    }

    static func deleteUserAgent(_ service: LaunchService) throws {
        guard service.scope == .userAgents else {
            throw CommandError.executionFailed("Only user agents can be deleted.")
        }

        if FileManager.default.fileExists(atPath: service.plistURL.path) {
            try FileManager.default.removeItem(at: service.plistURL)
        }
    }

    static func loadLogs(service: LaunchService) -> String {
        var sections: [String] = []

        if let outPath = service.plistDictionary.standardOutPath {
            sections.append(contentsOf: readLogFileSection(path: outPath, title: "StandardOutPath"))
        }

        if let errPath = service.plistDictionary.standardErrorPath {
            sections.append(contentsOf: readLogFileSection(path: errPath, title: "StandardErrorPath"))
        }

        if sections.isEmpty {
            let predicate = "eventMessage CONTAINS \"\(service.label.replacingOccurrences(of: "\"", with: "\\\""))\""
            let args = ["show", "--last", "1h", "--style", "compact", "--predicate", predicate]
            if let result = try? CommandRunner.run("/usr/bin/log", arguments: args), result.isSuccess {
                let lines = result.stdout.split(separator: "\n").suffix(200)
                let snippet = lines.joined(separator: "\n")
                sections.append("=== Unified Log (last 1h, filtered) ===\n\(snippet)")
            } else {
                sections.append("No log file paths found and unified log query returned no results.")
            }
        }

        return sections.joined(separator: "\n\n")
    }

    static func loadLogsSplit(service: LaunchService) -> (stdout: String, stderr: String, unified: String) {
        var stdoutContent = ""
        var stderrContent = ""
        var unifiedContent = ""

        if let outPath = service.plistDictionary.standardOutPath {
            let expanded = NSString(string: outPath).expandingTildeInPath
            if let snippet = readTailOfFile(atPath: expanded, maxLines: 500) {
                stdoutContent = snippet
            } else if !FileManager.default.fileExists(atPath: expanded) {
                stdoutContent = "File not found: \(expanded)"
            } else {
                stdoutContent = "Unable to read file: \(expanded)"
            }
        }

        if let errPath = service.plistDictionary.standardErrorPath {
            let expanded = NSString(string: errPath).expandingTildeInPath
            if let snippet = readTailOfFile(atPath: expanded, maxLines: 500) {
                stderrContent = snippet
            } else if !FileManager.default.fileExists(atPath: expanded) {
                stderrContent = "File not found: \(expanded)"
            } else {
                stderrContent = "Unable to read file: \(expanded)"
            }
        }

        if stdoutContent.isEmpty && stderrContent.isEmpty {
            let predicate = "eventMessage CONTAINS \"\(service.label.replacingOccurrences(of: "\"", with: "\\\""))\""
            let args = ["show", "--last", "1h", "--style", "compact", "--predicate", predicate]
            if let result = try? CommandRunner.run("/usr/bin/log", arguments: args), result.isSuccess {
                let lines = result.stdout.split(separator: "\n").suffix(200)
                unifiedContent = lines.joined(separator: "\n")
            } else {
                unifiedContent = "No log file paths found and unified log query returned no results."
            }
        }

        return (stdoutContent, stderrContent, unifiedContent)
    }

    // MARK: - Private

    private static func readTailOfFile(atPath path: String, maxLines: Int, maxBytes: UInt64 = 65536) -> String? {
        let expanded = NSString(string: path).expandingTildeInPath
        guard FileManager.default.fileExists(atPath: expanded),
              let attrs = try? FileManager.default.attributesOfItem(atPath: expanded),
              let fileSize = attrs[.size] as? UInt64,
              let handle = FileHandle(forReadingAtPath: expanded) else {
            return nil
        }
        defer { try? handle.close() }

        if fileSize > maxBytes {
            try? handle.seek(toOffset: fileSize - maxBytes)
        }
        let data = handle.readDataToEndOfFile()
        guard let text = String(data: data, encoding: .utf8) else { return nil }
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).suffix(maxLines)
        return lines.joined(separator: "\n")
    }

    private static func readLogFileSection(path: String, title: String) -> [String] {
        let expanded = NSString(string: path).expandingTildeInPath
        guard FileManager.default.fileExists(atPath: expanded) else {
            return ["=== \(title): \(expanded) ===\nFile does not exist."]
        }

        if let snippet = readTailOfFile(atPath: expanded, maxLines: 250) {
            return ["=== \(title): \(expanded) ===\n\(snippet)"]
        } else {
            return ["=== \(title): \(expanded) ===\nUnable to read file."]
        }
    }

    private static func parseFirstInt(in text: String, after token: String) -> Int? {
        guard let range = text.range(of: token) else { return nil }
        let suffix = text[range.upperBound...]
        let trimmed = suffix.trimmingCharacters(in: .whitespacesAndNewlines)
        let digits = trimmed.prefix { $0.isNumber }
        return Int(digits)
    }

    private static func nonEmptyError(from result: CommandResult) -> String {
        let stderr = result.stderr.trimmingCharacters(in: .whitespacesAndNewlines)
        if !stderr.isEmpty { return stderr }
        let stdout = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        if !stdout.isEmpty { return stdout }
        return "launchctl command failed with code \(result.exitCode)."
    }
}
