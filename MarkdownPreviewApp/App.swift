import SwiftUI

@main
struct MarkdownPreviewApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage(AppDelegate.followXcodeKey) private var followXcode = true
    @AppStorage("zoom") private var zoom = 1.0

    var body: some Scene {
        DocumentGroup(viewing: MarkdownDocument.self) { configuration in
            ReaderView(
                fileURL: configuration.fileURL,
                fallbackText: configuration.document.text
            )
        }
        .commands {
            CommandGroup(after: .toolbar) {
                Button("Actual Size") { zoom = 1.0 }
                    .keyboardShortcut("0", modifiers: .command)
                Button("Zoom In") { zoom = min(3.0, zoom + 0.1) }
                    .keyboardShortcut("+", modifiers: .command)
                Button("Zoom Out") { zoom = max(0.5, zoom - 0.1) }
                    .keyboardShortcut("-", modifiers: .command)
                Divider()
            }
            CommandMenu("Xcode") {
                Toggle("Follow Xcode Automatically", isOn: $followXcode)
            }
        }
    }
}
