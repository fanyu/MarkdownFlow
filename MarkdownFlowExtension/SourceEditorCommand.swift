import AppKit
import Foundation
import XcodeKit

class SourceEditorCommand: NSObject, XCSourceEditorCommand {
    func perform(with invocation: XCSourceEditorCommandInvocation,
                 completionHandler: @escaping (Error?) -> Void) {
        defer { completionHandler(nil) }
        // XcodeKit doesn't expose the file path; the app's XcodeWatcher
        // detects it via AppleScript. The command just signals a toggle
        // and makes sure the app is running.
        DistributedNotificationCenter.default().postNotificationName(
            Notification.Name("com.fanyu.markdownflow.toggle"),
            object: nil,
            userInfo: nil,
            deliverImmediately: true
        )
        launchAppIfNeeded()
    }

    private func launchAppIfNeeded() {
        let appBundleID = "com.fanyu.MarkdownFlow"
        guard NSRunningApplication.runningApplications(withBundleIdentifier: appBundleID).isEmpty,
              let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: appBundleID)
        else { return }
        let config = NSWorkspace.OpenConfiguration()
        config.activates = false
        NSWorkspace.shared.openApplication(at: appURL, configuration: config)
    }
}
