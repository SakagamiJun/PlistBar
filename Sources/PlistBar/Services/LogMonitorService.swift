import Foundation

actor LogMonitorService {
    private struct ActiveMonitor {
        let source: DispatchSourceFileSystemObject
        let path: String
    }

    private var monitors: [String: [ActiveMonitor]] = [:]
    private var offsets: [String: UInt64] = [:]

    func startMonitoring(
        service: LaunchService,
        onNewContent: @Sendable @escaping (String) -> Void
    ) {
        stopMonitoring(label: service.label)

        var pathsToMonitor: [String] = []
        if let outPath = service.plistDictionary.standardOutPath {
            pathsToMonitor.append(outPath)
        }
        if let errPath = service.plistDictionary.standardErrorPath,
           errPath != service.plistDictionary.standardOutPath {
            pathsToMonitor.append(errPath)
        }

        var serviceMonitors: [ActiveMonitor] = []

        for rawPath in pathsToMonitor {
            let expanded = NSString(string: rawPath).expandingTildeInPath
            guard FileManager.default.fileExists(atPath: expanded) else { continue }

            let fd = open(expanded, O_EVTONLY)
            guard fd >= 0 else { continue }

            let source = DispatchSource.makeFileSystemObjectSource(
                fileDescriptor: fd,
                eventMask: [.write, .extend, .rename],
                queue: DispatchQueue.global(qos: .background)
            )

            var currentOffset: UInt64 = 0
            if let attrs = try? FileManager.default.attributesOfItem(atPath: expanded),
               let size = attrs[.size] as? UInt64 {
                currentOffset = size
            }
            offsets[expanded] = currentOffset

            source.setEventHandler { [weak self] in
                guard let self else { return }
                Task {
                    let newContent = await self.readNewContent(path: expanded)
                    if !newContent.isEmpty {
                        onNewContent(newContent)
                    }
                }
            }

            source.setCancelHandler {
                close(fd)
            }

            source.resume()
            serviceMonitors.append(ActiveMonitor(source: source, path: expanded))
        }

        if !serviceMonitors.isEmpty {
            monitors[service.label] = serviceMonitors
        }
    }

    func stopMonitoring(label: String) {
        guard let list = monitors.removeValue(forKey: label) else { return }
        for item in list {
            item.source.cancel()
            offsets.removeValue(forKey: item.path)
        }
    }

    func stopAll() {
        for (_, list) in monitors {
            for item in list {
                item.source.cancel()
            }
        }
        monitors.removeAll()
        offsets.removeAll()
    }

    private func readNewContent(path: String) -> String {
        let currentOffset = offsets[path] ?? 0
        guard let handle = FileHandle(forReadingAtPath: path) else { return "" }
        defer { try? handle.close() }

        guard let attrs = try? FileManager.default.attributesOfItem(atPath: path),
              let fileSize = attrs[.size] as? UInt64 else { return "" }

        let seekPos: UInt64
        if fileSize < currentOffset {
            seekPos = 0
        } else {
            seekPos = currentOffset
        }

        try? handle.seek(toOffset: seekPos)
        // Bound incremental read to 64KB to prevent sudden memory spikes
        let maxChunk = 65536
        let data = handle.readData(ofLength: maxChunk)
        offsets[path] = seekPos + UInt64(data.count)
        return String(data: data, encoding: .utf8) ?? ""
    }
}
