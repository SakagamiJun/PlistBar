import Foundation

actor FileWatcherService {
    private var stream: FSEventStreamRef?

    func watch(directories: [URL], onChange: @Sendable @escaping () -> Void) {
        stop()

        let paths = directories.map { $0.path as CFString } as CFArray

        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passRetained(WatcherCallback(callback: onChange)).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let stream = FSEventStreamCreate(
            nil,
            { (_, info, numEvents, eventPaths, _, _) in
                guard let info else { return }
                let callback = Unmanaged<WatcherCallback>.fromOpaque(info).takeUnretainedValue()
                callback.callback()
            },
            &context,
            paths,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            1.0,
            FSEventStreamCreateFlags(
                kFSEventStreamCreateFlagUseCFTypes
                | kFSEventStreamCreateFlagFileEvents
            )
        )

        guard let stream else { return }

        FSEventStreamSetDispatchQueue(stream, DispatchQueue.global(qos: .background))
        FSEventStreamStart(stream)
        self.stream = stream
    }

    func stop() {
        guard let stream else { return }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        self.stream = nil
    }
}

/// Wrapper to pass a Sendable closure through FSEventStream's C callback context.
private final class WatcherCallback: @unchecked Sendable {
    let callback: @Sendable () -> Void
    init(callback: @escaping @Sendable () -> Void) {
        self.callback = callback
    }
}
