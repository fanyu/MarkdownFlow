import WebKit

struct Heading: Identifiable, Hashable {
    let id: String
    let text: String
    let level: Int
}

/// Owns a WKWebView's rendering lifecycle: loads the bundled preview.html
/// template, injects markdown via JSON-safe evaluateJavaScript calls, and
/// relays TOC updates posted from JS.
final class Renderer: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    let webView: WKWebView

    var onTOCChanged: (([Heading]) -> Void)?

    private var templateLoaded = false
    private var pendingJS: [String] = []

    override init() {
        let config = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: config)
        super.init()
        config.userContentController.add(self, name: "toc")
        webView.navigationDelegate = self
        webView.setValue(false, forKey: "drawsBackground")  // avoid white flash in dark mode
        loadTemplate()
    }

    private func loadTemplate() {
        guard let url = Bundle.main.url(forResource: "preview", withExtension: "html") else {
            assertionFailure("preview.html not found in bundle")
            return
        }
        // Allow read access to the whole disk so relative images in documents
        // resolve. The app is not sandboxed, so this adds no extra privilege.
        webView.loadFileURL(url, allowingReadAccessTo: URL(fileURLWithPath: "/"))
    }

    /// Render a markdown string; baseDir resolves relative image paths.
    func render(markdown: String, baseDir: String?) {
        let content = jsonString(markdown)
        let dir = baseDir.map(jsonString) ?? "null"
        // void: renderMarkdown is async; a returned Promise can't cross the JS bridge
        evaluate("void renderMarkdown(\(content), \(dir))")
    }

    /// Render the file at path, or a placeholder if it can't be read.
    func renderFile(at path: String) {
        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            render(markdown: "*Cannot read file: \(path)*", baseDir: nil)
            return
        }
        render(markdown: content, baseDir: (path as NSString).deletingLastPathComponent)
    }

    /// theme: "light" | "dark" | "auto"
    func setTheme(_ theme: String) {
        evaluate("setTheme(\(jsonString(theme)))")
    }

    func scrollToHeading(id: String) {
        evaluate("scrollToHeading(\(jsonString(id)))")
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        templateLoaded = true
        let queued = pendingJS
        pendingJS = []
        queued.forEach { run($0) }
    }

    // MARK: - WKScriptMessageHandler

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        guard message.name == "toc", let items = message.body as? [[String: Any]] else { return }
        let headings = items.compactMap { item -> Heading? in
            guard let id = item["id"] as? String,
                  let text = item["text"] as? String,
                  let level = item["level"] as? Int else { return nil }
            return Heading(id: id, text: text, level: level)
        }
        onTOCChanged?(headings)
    }

    // MARK: - Private

    private func evaluate(_ js: String) {
        if templateLoaded {
            run(js)
        } else {
            pendingJS.append(js)
        }
    }

    private func run(_ js: String) {
        webView.evaluateJavaScript(js) { _, error in
            if let error { NSLog("Renderer JS error: %@", error.localizedDescription) }
        }
    }

    /// JSON-encodes the string so it's safe to embed as a JS argument.
    private func jsonString(_ string: String) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: string, options: .fragmentsAllowed),
              let result = String(data: data, encoding: .utf8) else {
            return "\"\""
        }
        return result
    }
}
