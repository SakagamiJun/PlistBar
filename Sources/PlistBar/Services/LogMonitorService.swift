import Foundation

actor LogMonitorService {
    private var monitors: [String: DispatchSourceFileSystemObject] = [:]
    private var offsets: [String: UInt64] = [:]

    func startMonitoring(
        service: LaunchService,
        onNewContent: @Sendable @escaping (String) -> Void
    ) {
        stopMonitoring(label: service.label)

        guard let path = service.plistDictionary.standardOutPath else { return }
        let expanded = NSString(string: path).expandingTildeInPath

        guard FileManager.default.fileExists(atPath: expanded) else { return }

        let fd = open(expanded, O_EVTONLY)
        guard fd >= 0 else { return }

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
        offsets[service.label] = currentOffset

        let label = service.label
        source.setEventHandler { [weak self] in
            guard let self else { return }
            Task {
                let newContent = await self.readNewContent(path: expanded, label: label)
                if !newContent.isEmpty {
                    onNewContent(newContent)
                }
            }
        }

        source.setCancelHandler {
            close(fd)
        }

        source.resume()
        monitors[service.label] = source
    }

    func stopMonitoring(label: String) {
        monitors[label]?.cancel()
        monitors.removeValue(forKey: label)
        offsets.removeValue(forKey: label)
    }

    func stopAll() {
        for (_, source) in monitors {
            source.cancel()
        }
        monitors.removeAll()
        offsets.removeAll()
    }

    private func readNewContent(path: String, label: String) -> String {
        let currentOffset = offsets[label] ?? 0
        guard let handle = FileHandle(forReadingAtPath: path) else { return "" }
        defer { try? handle.close() }

        guard let attrs = try? FileManager.default.attributesOfItem(atPath: path),
              let fileSize = attrs[.size] as? UInt64 else { return "" }

        let seekPos: UInt64
        if fileSize < currentOffset {
            // File was truncated or rotated
            seekPos = 0
        } else {
            seekPos = currentOffset
        }

        try? handle.seek(toOffset: seekPos)
        // Bound incremental read to 64KB to prevent sudden memory spikes
        let maxChunk = 65536
        let data = handle.readData(ofLength: maxChunk)
        offsets[label] = seekPos + UInt64(data.count)
        return String(data: data, encoding: .utf8) ?? ""
    }
}
