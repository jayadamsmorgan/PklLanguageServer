import Foundation
import LanguageServerProtocol
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

extension Document {
    public func withAppliedChanges(_ changes: [TextDocumentContentChangeEvent], nextVersion: Int?) throws -> Document {
        var text = self.text
        for change in changes {
            try Document.applyChange(change, on: &text)
        }
        return Document(uri: uri, version: nextVersion, text: text)
    }

    private static func findPosition(_ position: Position, in text: String, startIndex: String.Index, startPos: Position) -> String.Index? {
        let lineStart = text.index(startIndex, offsetBy: -startPos.character)

        var it = text[lineStart...]
        for _ in startPos.line..<position.line {
            guard let index = it.firstIndex(of: "\n") else {
                return nil
            }
            it = it[it.index(after: index)...]
        }
        return text.index(it.startIndex, offsetBy: position.character)
    }

    public func getTextInByteRange(_ range: Range<UInt32>) -> String {
        let start = text.index(text.startIndex, offsetBy: Int(range.lowerBound / 2))
        let end = text.index(text.startIndex, offsetBy: Int(range.upperBound / 2))
        return String(text[start..<end])
    }

    public static func findPosition(_ position: Position, in text: String) -> String.Index? {
        findPosition(position, in: text, startIndex: text.startIndex, startPos: Position.zero)
    }

    public static func findRange(_ range: LSPRange, in text: String) -> Range<String.Index>? {
        guard let startIndex = findPosition(range.start, in: text) else {
            return nil
        }

        guard let endIndex = findPosition(range.end, in: text, startIndex: startIndex, startPos: range.start) else {
            return nil
        }

        return startIndex..<endIndex
    }

    public static func applyChange(_ change: TextDocumentContentChangeEvent, on text: inout String) throws {

        if let range = change.range {

            guard let range = findRange(range, in: change.text) else {
                throw InvalidDocumentChangeRange(range: range)
            }

            text.replaceSubrange(range, with: change.text)

        } else {
            text = change.text
        }
    }
}


