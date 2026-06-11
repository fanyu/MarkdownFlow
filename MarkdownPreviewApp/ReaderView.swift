import SwiftUI

/// One document window: TOC sidebar + rendered markdown, with an optional
/// source editor pane on the left when editing.
struct ReaderView: View {
    @Binding var document: MarkdownDocument
    let fileURL: URL?

    @AppStorage("theme") private var theme = "auto"
    @AppStorage("zoom") private var zoom = 1.0
    @State private var isEditing: Bool
    @State private var toc: [Heading] = []
    @State private var currentHeadingID: String?
    @State private var scrollTarget: String?

    init(document: Binding<MarkdownDocument>, fileURL: URL?) {
        _document = document
        self.fileURL = fileURL
        // New, never-saved documents open straight into the editor.
        _isEditing = State(initialValue: fileURL == nil)
    }

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
            HSplitView {
                if isEditing {
                    SourceEditor(text: $document.text)
                        .frame(minWidth: 240)
                }
                MarkdownWebView(
                    text: document.text,
                    baseDir: fileURL.map { $0.deletingLastPathComponent().path },
                    theme: theme,
                    zoom: zoom,
                    toc: $toc,
                    currentHeadingID: $currentHeadingID,
                    scrollTarget: $scrollTarget
                )
                .frame(minWidth: 280, maxWidth: .infinity, maxHeight: .infinity)
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Toggle(isOn: $isEditing.animation()) {
                    Label("Edit", systemImage: "square.and.pencil")
                }
                .toggleStyle(.button)
                .help(isEditing ? "隐藏编辑器" : "编辑 Markdown 源文件")
            }
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

/// Plain-text markdown source editor.
private struct SourceEditor: View {
    @Binding var text: String

    var body: some View {
        TextEditor(text: $text)
            .font(.system(size: 13, design: .monospaced))
            .lineSpacing(3)
            .autocorrectionDisabled()
            .scrollContentBackground(.hidden)
            .background(Color(nsColor: .textBackgroundColor))
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
