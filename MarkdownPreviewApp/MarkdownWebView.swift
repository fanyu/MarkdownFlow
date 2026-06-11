import SwiftUI
import WebKit

/// Hosts one Renderer-backed WKWebView per reader window, with live reload
/// of the displayed file via FSEvents.
struct MarkdownWebView: NSViewRepresentable {
    let fileURL: URL?
    let fallbackText: String
    let theme: String
    let zoom: Double
    @Binding var toc: [Heading]
    @Binding var currentHeadingID: String?
    @Binding var scrollTarget: String?

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> WKWebView {
        let coordinator = context.coordinator
        bind(coordinator)
        coordinator.load(fileURL: fileURL, fallbackText: fallbackText)
        coordinator.renderer.setTheme(theme)
        return coordinator.renderer.webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        let coordinator = context.coordinator
        bind(coordinator)
        nsView.pageZoom = zoom
        coordinator.setTheme(theme)
        coordinator.load(fileURL: fileURL, fallbackText: fallbackText)
        if let target = scrollTarget {
            coordinator.renderer.scrollToHeading(id: target)
            DispatchQueue.main.async { scrollTarget = nil }
        }
    }

    private func bind(_ coordinator: Coordinator) {
        coordinator.onTOC = { headings in
            DispatchQueue.main.async { toc = headings }
        }
        coordinator.onSpy = { id in
            DispatchQueue.main.async { currentHeadingID = id }
        }
    }

    final class Coordinator {
        let renderer = Renderer()
        private let monitor = FileMonitor()
        private var loadedPath: String?
        private var currentTheme: String?
        private var fallbackTextRendered: String?
        var onTOC: (([Heading]) -> Void)?
        var onSpy: ((String?) -> Void)?

        init() {
            renderer.onTOCChanged = { [weak self] headings in
                self?.onTOC?(headings)
            }
            renderer.onCurrentHeadingChanged = { [weak self] id in
                self?.onSpy?(id)
            }
        }

        func setTheme(_ theme: String) {
            guard theme != currentTheme else { return }
            currentTheme = theme
            renderer.setTheme(theme)
        }

        func load(fileURL: URL?, fallbackText: String) {
            guard let path = fileURL?.path else {
                if loadedPath != nil || fallbackTextRendered != fallbackText {
                    fallbackTextRendered = fallbackText
                    renderer.render(markdown: fallbackText, baseDir: nil)
                }
                return
            }
            guard path != loadedPath else { return }
            loadedPath = path
            renderer.renderFile(at: path)
            monitor.onChange = { [weak self] changedPath in
                self?.renderer.renderFile(at: changedPath)
            }
            monitor.start(watching: path)
        }
    }
}
