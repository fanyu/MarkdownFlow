import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let markdownDoc = UTType(importedAs: "net.daringfireball.markdown")
}

/// Read-only document: content is re-read from disk by the reader (for live
/// reload), so this only carries the initial text as a fallback.
struct MarkdownDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.markdownDoc]

    var text: String

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = String(decoding: data, as: UTF8.self)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        throw CocoaError(.fileWriteNoPermission)  // viewer only
    }
}
