import Foundation
import LanguageServerProtocol
import Logging
import SwiftTreeSitter

public struct Document: Hashable {
    public let uri: DocumentUri
    public let version: Int?
    public let text: String

    public init(uri: DocumentUri, version: Int?, text: String) {
        self.uri = uri
        self.version = version
        self.text = text
    }

    public init(textDocument: TextDocumentItem) {
        uri = textDocument.uri
        version = textDocument.version
        text = textDocument.text
    }
}

struct InvalidDocumentChangeRange: Error {
    public let range: LSPRange
}

struct NilDocumentChangeRange: Error {}

public extension Document {
    func withAppliedChanges(_ changes: [TextDocumentContentChangeEvent], nextVersion: Int?) throws -> Document {
        var text = text
        for change in changes {
            try Document.applyChange(change, on: &text)
        }
        return Document(uri: uri, version: nextVersion, text: text)
    }

    private static func findPosition(_ position: Position, in text: String, startIndex: String.Index, startPos: Position) -> String.Index? {
        let lineStart = text.index(startIndex, offsetBy: -startPos.character)

        var it = text[lineStart...]
        for _ in startPos.line ..< position.line {
            guard let index = it.firstIndex(of: "\n") else {
                return nil
            }
            it = it[it.index(after: index)...]
        }
        return text.index(it.startIndex, offsetBy: position.character)
    }

    func getTextInByteRange(_ range: Range<UInt32>) -> String {
        let start = text.index(text.startIndex, offsetBy: Int(range.lowerBound / 2))
        let end = text.index(text.startIndex, offsetBy: Int(range.upperBound / 2))
        return String(text[start ..< end])
    }

    static func findPosition(_ position: Position, in text: String) -> String.Index? {
        findPosition(position, in: text, startIndex: text.startIndex, startPos: Position.zero)
    }

    static func findRange(_ range: LSPRange, in text: String) -> Range<String.Index>? {
        guard let startIndex = findPosition(range.start, in: text) else {
            return nil
        }

        guard let endIndex = findPosition(range.end, in: text, startIndex: startIndex, startPos: range.start) else {
            return nil
        }

        return startIndex ..< endIndex
    }

    static func applyChange(_ change: TextDocumentContentChangeEvent, on text: inout String) throws {
        if let range = change.range {
            guard let range = findRange(range, in: text) else {
                throw InvalidDocumentChangeRange(range: range)
            }

            text.replaceSubrange(range, with: change.text)

        } else {
            text = change.text
        }
    }

    struct TSInputEditsForDocument {
        let inputEdits: [InputEdit]
        let document: Document
    }

    static func getTSInputEditsApplyingChanges(for document: Document, with changes: [TextDocumentContentChangeEvent], nextVersion: Int? = nil)
        throws -> TSInputEditsForDocument
    {
        // Range length is actually deprecated since LSP 3.15, so we don't need to handle it as we can just use the range to replace the text
        var text = document.text
        var inputEdits: [InputEdit] = []
        for change in changes {
            guard let range = change.range else {
                throw NilDocumentChangeRange()
            }
            guard let range = findRange(range, in: document.text) else {
                throw InvalidDocumentChangeRange(range: range)
            }
            let startByte = range.lowerBound.utf16Offset(in: text) * 2
            let oldEndByte = range.upperBound.utf16Offset(in: text) * 2
            let newEndByte = startByte + (change.text.count * 2)
            let startPoint = change.range?.start.getPoint() ?? Point.zero
            let oldEndPoint = change.range?.end.getPoint() ?? Point.zero
            let split = change.text.split(separator: "\n")
            let splitCount = split.count > 0 ? split.count - 1 : 0
            let lastCount = split.last?.count ?? 0
            let newEndPoint = Point(row: Int(startPoint.row) + splitCount,
                                    column: Int(startPoint.column) + lastCount)
            text.replaceSubrange(range, with: change.text)

            let inputEdit = InputEdit(
                startByte: startByte,
                oldEndByte: oldEndByte,
                newEndByte: newEndByte,
                startPoint: startPoint,
                oldEndPoint: oldEndPoint,
                newEndPoint: newEndPoint
            )
            inputEdits.append(inputEdit)
        }
        return TSInputEditsForDocument(inputEdits: inputEdits, document: Document(uri: document.uri, version: nextVersion, text: text))
    }
}
