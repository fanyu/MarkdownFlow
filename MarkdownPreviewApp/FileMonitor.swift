import Foundation

final class FileMonitor {
    private var eventStream: FSEventStreamRef?
    private var currentPath: String?
    var onChange: ((String) -> Void)?  // called with file path on change

    func start(watching path: String) {
        stop()
        currentPath = path
        let pathsToWatch = [path] as CFArray
        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil, release: nil, copyDescription: nil
        )
        eventStream = FSEventStreamCreate(
            nil,
            { _, info, _, _, _, _ in
                guard let info else { return }
                let monitor = Unmanaged<FileMonitor>.fromOpaque(info).takeUnretainedValue()
                if let path = monitor.currentPath {
                    DispatchQueue.main.async { monitor.onChange?(path) }
                }
            },
            &context,
            pathsToWatch,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.3,  // 300ms latency — fast enough for saves, avoids thrash
            FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes)
        )
        guard let stream = eventStream else { return }
        FSEventStreamSetDispatchQueue(stream, .main)
        FSEventStreamStart(stream)
    }

    func stop() {
        guard let stream = eventStream else { return }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        eventStream = nil
        currentPath = nil
    }

    deinit { stop() }
}
