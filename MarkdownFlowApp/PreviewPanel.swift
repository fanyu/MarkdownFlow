import AppKit
import WebKit

/// Floating non-activating panel for Xcode follow mode. Shows the rendered
/// markdown without stealing focus from Xcode.
final class PreviewPanel: NSPanel {
    let renderer = Renderer()

    convenience init() {
        self.init(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 700),
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        title = "Markdown Preview"
        isFloatingPanel = true
        isReleasedWhenClosed = false
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let webView = renderer.webView
        webView.translatesAutoresizingMaskIntoConstraints = false
        let container = NSView()
        container.addSubview(webView)
        contentView = container
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: container.topAnchor),
            webView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        positionAtScreenRight()
    }

    func setFilename(_ name: String) {
        title = name.isEmpty ? "Markdown Preview" : name
    }

    private func positionAtScreenRight() {
        guard let screen = NSScreen.main else { return }
        let frame = screen.visibleFrame
        let width: CGFloat = 500
        let height = min(750, frame.height - 40)
        setFrame(
            NSRect(x: frame.maxX - width - 8,
                   y: frame.midY - height / 2,
                   width: width, height: height),
            display: false
        )
    }
}
