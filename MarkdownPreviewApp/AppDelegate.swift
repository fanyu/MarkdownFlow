import AppKit

/// Wires Xcode follow mode: XcodeWatcher detects the active .md in Xcode,
/// FileMonitor tracks saves, PreviewPanel displays. Also listens for the
/// Source Editor Extension's toggle notification.
final class AppDelegate: NSObject, NSApplicationDelegate {
    static let followXcodeKey = "followXcode"
    static let toggleNotification = Notification.Name("com.fanyu.markdownpreview.toggle")

    private lazy var panel = PreviewPanel()
    private let watcher = XcodeWatcher()
    private let fileMonitor = FileMonitor()
    private var watcherRunning = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.register(defaults: [Self.followXcodeKey: true])

        watcher.onFilePathChanged = { [weak self] path in
            self?.handleActiveFileChanged(to: path)
        }
        updateFollowMode()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(defaultsChanged),
            name: UserDefaults.didChangeNotification,
            object: nil
        )
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(extensionTriggered),
            name: Self.toggleNotification,
            object: nil,
            suspensionBehavior: .deliverImmediately
        )
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false  // keep running for Xcode follow mode
    }

    // MARK: - Follow mode

    @objc private func defaultsChanged() {
        updateFollowMode()
    }

    private func updateFollowMode() {
        let enabled = UserDefaults.standard.bool(forKey: Self.followXcodeKey)
        guard enabled != watcherRunning else { return }
        watcherRunning = enabled
        if enabled {
            watcher.start()
        } else {
            watcher.stop()
            fileMonitor.stop()
            panel.orderOut(nil)
        }
    }

    private func handleActiveFileChanged(to path: String?) {
        if let path {
            panel.setFilename((path as NSString).lastPathComponent)
            panel.renderer.renderFile(at: path)
            fileMonitor.onChange = { [weak self] changedPath in
                self?.panel.renderer.renderFile(at: changedPath)
            }
            fileMonitor.start(watching: path)
            if !panel.isVisible { panel.orderFront(nil) }
        } else {
            fileMonitor.stop()
            panel.orderOut(nil)
        }
    }

    @objc private func extensionTriggered() {
        if panel.isVisible {
            panel.orderOut(nil)
        } else if UserDefaults.standard.bool(forKey: Self.followXcodeKey) == false {
            // Follow mode off: turning the panel on via the Xcode command
            // re-enables following so the panel has content to show.
            UserDefaults.standard.set(true, forKey: Self.followXcodeKey)
        } else {
            panel.orderFront(nil)
        }
    }
}
