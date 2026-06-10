import SwiftUI

/// One document window: TOC sidebar + rendered markdown.
struct ReaderView: View {
    let fileURL: URL?
    let fallbackText: String

    @AppStorage("theme") private var theme = "auto"
    @AppStorage("zoom") private var zoom = 1.0
    @State private var toc: [Heading] = []
    @State private var scrollTarget: String?

    var body: some View {
        NavigationSplitView {
            List(toc, selection: Binding<String?>(
                get: { nil },
                set: { id in if let id { scrollTarget = id } }
            )) { heading in
                Text(heading.text)
                    .lineLimit(2)
                    .font(heading.level == 1 ? .body.weight(.semibold) : .body)
                    .padding(.leading, CGFloat(max(0, heading.level - 1)) * 12)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 160, ideal: 210, max: 320)
            .overlay {
                if toc.isEmpty {
                    Text("No Headings")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                }
            }
        } detail: {
            MarkdownWebView(
                fileURL: fileURL,
                fallbackText: fallbackText,
                theme: theme,
                zoom: zoom,
                toc: $toc,
                scrollTarget: $scrollTarget
            )
            .ignoresSafeArea(edges: .bottom)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Picker("Theme", selection: $theme) {
                    Label("Auto", systemImage: "circle.lefthalf.filled").tag("auto")
                    Label("Light", systemImage: "sun.max").tag("light")
                    Label("Dark", systemImage: "moon").tag("dark")
                }
                .pickerStyle(.segmented)
                .help("Preview theme")
            }
        }
    }
}
