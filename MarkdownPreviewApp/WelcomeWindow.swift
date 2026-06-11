import AppKit
import SwiftUI

/// Xcode-style welcome window: app identity + new/open actions on the left,
/// recent documents on the right. Shown when the app has no document windows.
final class WelcomeWindowController: NSWindowController, NSWindowDelegate {
    var onClose: (() -> Void)?

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 760, height: 440),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.contentView = NSHostingView(rootView: WelcomeView())
        window.center()
        self.init(window: window)
        window.delegate = self
    }

    func windowWillClose(_ notification: Notification) {
        onClose?()
    }
}

private struct WelcomeView: View {
    var body: some View {
        HStack(spacing: 0) {
            actionPane
                .frame(width: 460)
            RecentFilesPane()
                .frame(width: 300)
                .background(.regularMaterial)
        }
        .frame(width: 760, height: 440)
        .ignoresSafeArea()
    }

    private var actionPane: some View {
        VStack(spacing: 0) {
            Spacer()
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 128, height: 128)
            Text("MarkdownPreview")
                .font(.system(size: 30, weight: .regular))
                .padding(.top, 8)
            Text("版本 \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 10) {
                WelcomeActionButton(
                    icon: "square.and.pencil",
                    title: "新建 Markdown 文件",
                    subtitle: "创建一个空白文档并开始编辑"
                ) {
                    NSDocumentController.shared.newDocument(nil)
                }
                WelcomeActionButton(
                    icon: "folder",
                    title: "打开文件…",
                    subtitle: "浏览 Markdown 文件（⌘O）"
                ) {
                    NSDocumentController.shared.openDocument(nil)
                }
            }
            .padding(.top, 28)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

private struct WelcomeActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 30)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.system(size: 11.5))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(width: 320, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(hovering ? Color.primary.opacity(0.07) : .clear)
            )
            .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

private struct RecentFilesPane: View {
    @State private var recents: [URL] = []

    var body: some View {
        Group {
            if recents.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 28))
                        .foregroundStyle(.tertiary)
                    Text("没有最近打开的文件")
                        .font(.system(size: 12.5))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(recents, id: \.self) { url in
                            RecentFileRow(url: url)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 36)
                    .padding(.bottom, 12)
                }
            }
        }
        .onAppear {
            recents = NSDocumentController.shared.recentDocumentURLs
        }
    }
}

private struct RecentFileRow: View {
    let url: URL

    @State private var hovering = false

    var body: some View {
        Button {
            NSDocumentController.shared.openDocument(
                withContentsOf: url, display: true
            ) { _, _, _ in }
        } label: {
            HStack(spacing: 9) {
                Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                    .resizable()
                    .frame(width: 30, height: 30)
                VStack(alignment: .leading, spacing: 1) {
                    Text(url.lastPathComponent)
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text(displayPath)
                        .font(.system(size: 10.5))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(hovering ? Color.primary.opacity(0.08) : .clear)
            )
            .contentShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }

    private var displayPath: String {
        let dir = url.deletingLastPathComponent().path
        return (dir as NSString).abbreviatingWithTildeInPath
    }
}
