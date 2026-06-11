import SwiftUI
import WebKit

/// Hosts one Renderer-backed WKWebView per reader window, rendering the
/// document text live (debounced while typing).
struct MarkdownWebView: NSViewRepresentable {
    let text: String
    let baseDir: String?
    let theme: String
    let zoom: Double
    @Binding var toc: [Heading]
    @Binding var currentHeadingID: String?
    @Binding var scrollTarget: String?

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> WKWebView {
        let coordinator = context.coordinator
        bind(coordinator)
        coordinator.render(text: text, baseDir: baseDir, immediate: true)
        coordinator.setTheme(theme)
        return coordinator.renderer.webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        let coordinator = context.coordinator
        bind(coordinator)
        nsView.pageZoom = zoom
        coordinator.setTheme(theme)
        coordinator.render(text: text, baseDir: baseDir, immediate: false)
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
        private var renderedText: String?
        private var renderedBaseDir: String?
        private var currentTheme: String?
        private var pendingRender: DispatchWorkItem?
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

        func render(text: String, baseDir: String?, immediate: Bool) {
            guard text != renderedText || baseDir != renderedBaseDir else { return }
            pendingRender?.cancel()
            let work = DispatchWorkItem { [weak self] in
                guard let self else { return }
                self.renderedText = text
                self.renderedBaseDir = baseDir
                self.renderer.render(markdown: text, baseDir: baseDir)
            }
            pendingRender = work
            if immediate || renderedText == nil {
                work.perform()
            } else {
                // Debounce keystrokes so mermaid re-renders don't thrash.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
            }
        }
    }
}
