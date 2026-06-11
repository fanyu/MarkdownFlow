import AppKit

final class XcodeWatcher {
    var onFilePathChanged: ((String?) -> Void)?  // nil = no .md file active

    private var pollTimer: Timer?
    private var lastReportedPath: String?

    func start() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appActivated(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appDeactivated(_:)),
            name: NSWorkspace.didDeactivateApplicationNotification,
            object: nil
        )
        if NSWorkspace.shared.frontmostApplication?.bundleIdentifier == "com.apple.dt.Xcode" {
            startPolling()
        }
    }

    func stop() {
        pollTimer?.invalidate()
        pollTimer = nil
        lastReportedPath = nil
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    @objc private func appActivated(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              app.bundleIdentifier == "com.apple.dt.Xcode" else { return }
        startPolling()
    }

    @objc private func appDeactivated(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              app.bundleIdentifier == "com.apple.dt.Xcode" else { return }
        pollTimer?.invalidate()
        pollTimer = nil
    }

    private func startPolling() {
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkXcodeDocument()
        }
        checkXcodeDocument()  // check immediately on Xcode activation
    }

    private func checkXcodeDocument() {
        let script = """
        tell application "Xcode"
            if (count of documents) > 0 then
                get path of document 1
            else
                ""
            end if
        end tell
        """
        guard let appleScript = NSAppleScript(source: script) else { return }
        var errorDict: NSDictionary?
        let result = appleScript.executeAndReturnError(&errorDict)
        if errorDict != nil { return }
        let path = result.stringValue ?? ""
        let mdPath: String? = path.hasSuffix(".md") || path.hasSuffix(".markdown") ? path : nil

        guard mdPath != lastReportedPath else { return }
        lastReportedPath = mdPath
        DispatchQueue.main.async { self.onFilePathChanged?(mdPath) }
    }
}
