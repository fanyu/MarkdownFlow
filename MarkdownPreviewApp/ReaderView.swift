import SwiftUI

/// One document window: TOC sidebar + rendered markdown.
struct ReaderView: View {
    let fileURL: URL?
    let fallbackText: String

    @AppStorage("theme") private var theme = "auto"
    @AppStorage("zoom") private var zoom = 1.0
    @State private var toc: [Heading] = []
    @State private var currentHeadingID: String?
    @State private var scrollTarget: String?

    var body: some View {
        NavigationSplitView {
            ScrollViewReader { proxy in
                List(toc) { heading in
                    TOCRow(
                        heading: heading,
                        isCurrent: heading.id == currentHeadingID,
                        onTap: { scrollTarget = heading.id }
                    )
                    .id(heading.id)
                }
                .listStyle(.sidebar)
                .onChange(of: currentHeadingID) { id in
                    if let id { withAnimation { proxy.scrollTo(id) } }
                }
            }
            .navigationSplitViewColumnWidth(min: 170, ideal: 230, max: 360)
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
                currentHeadingID: $currentHeadingID,
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

private struct TOCRow: View {
    let heading: Heading
    let isCurrent: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                if heading.level > 1 {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.25))
                        .frame(width: 2)
                        .padding(.vertical, 1)
                }
                Text(heading.text)
                    .font(font)
                    .foregroundStyle(color)
                    .lineLimit(2)
                Spacer(minLength: 0)
            }
            .padding(.leading, CGFloat(max(0, heading.level - 1)) * 14)
            .padding(.vertical, heading.level == 1 ? 3 : 1)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(
            isCurrent
                ? RoundedRectangle(cornerRadius: 5).fill(Color.accentColor.opacity(0.18))
                : nil
        )
    }

    private var font: Font {
        switch heading.level {
        case 1: return .system(size: 13, weight: .bold)
        case 2: return .system(size: 12.5, weight: .medium)
        default: return .system(size: 12)
        }
    }

    private var color: Color {
        if isCurrent { return .accentColor }
        return heading.level <= 2 ? .primary : .secondary
    }
}
