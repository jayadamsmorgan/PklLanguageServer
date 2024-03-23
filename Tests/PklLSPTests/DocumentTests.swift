import Foundation
import LanguageServerProtocol
import SwiftTreeSitter
@testable import pkl_lsp
import XCTest

class DocumentTests: XCTestCase {

    let document = Document(uri: "file:///test.pkl", version: 0,
                            text: """
                            let a = 1
                            let b = 2
                            let c = 3
                            """)

    public func testApplyingChanges() async throws {
        // Range length is deprecated since LSP 3.15, so we don't need to handle it as we can just use the range to replace the text
        var document = document
        var changes = [
            TextDocumentContentChangeEvent(
                range: LSPRange(start: Position(line: 0, character: 4), end: Position(line: 0, character: 5)),
                rangeLength: nil,
                text: "b"
            ),
            TextDocumentContentChangeEvent(
                range: LSPRange(start: Position(line: 1, character: 4), end: Position(line: 2, character: 5)),
                rangeLength: nil,
                text: ""
            ),
        ]
        document = try document.withAppliedChanges(changes, nextVersion: 1)
        XCTAssertEqual(document.text, """
        let b = 1
        let  = 3
        """)
        changes = [
            TextDocumentContentChangeEvent(
                range: nil,
                rangeLength: nil,
                text: "let b = 2"
            ),
        ]
        document = try document.withAppliedChanges(changes, nextVersion: 2)
        XCTAssertEqual(document.text, "let b = 2")

        changes = [
            TextDocumentContentChangeEvent(
                range: LSPRange(start: Position(line: 0, character: 8), end: Position(line: 0, character: 9)),
                rangeLength: nil,
                text: "3"
            ),
        ]
        document = try document.withAppliedChanges(changes, nextVersion: 3)
        XCTAssertEqual(document.text, "let b = 3")

        changes = [
            TextDocumentContentChangeEvent(
                range: nil, rangeLength: nil, text: "" 
            ),
        ]
        document = try document.withAppliedChanges(changes, nextVersion: 4)
        XCTAssertEqual(document.text, "")
    }

    public func testGetTSInputEditsApplyingChanges() async throws {
        var document = document
        var changes = [
            TextDocumentContentChangeEvent(
                range: LSPRange(start: Position(line: 0, character: 4), end: Position(line: 0, character: 5)),
                rangeLength: nil,
                text: "b"
            ),
            TextDocumentContentChangeEvent(
                range: LSPRange(start: Position(line: 1, character: 4), end: Position(line: 2, character: 5)),
                rangeLength: nil,
                text: ""
            ),
        ]
        var edits = try Document.getTSInputEditsApplyingChanges(for: document, with: changes)
        document = edits.document
        var inputEdits = edits.inputEdits
        XCTAssertEqual(document.text, """
        let b = 1
        let  = 3
        """)
        XCTAssertEqual(inputEdits.count, 2)
        XCTAssertEqual(
            inputEdits[0],
            InputEdit(
                startByte: 8,
                oldEndByte: 10,
                newEndByte: 10,
                startPoint: Point(row: 0, column: 4),
                oldEndPoint: Point(row: 0, column: 5),
                newEndPoint: Point(row: 0, column: 5)
            )
        )
        XCTAssertEqual(
            inputEdits[1],
            InputEdit(
                startByte: 28,
                oldEndByte: 50,
                newEndByte: 28,
                startPoint: Point(row: 1, column: 4),
                oldEndPoint: Point(row: 2, column: 5),
                newEndPoint: Point(row: 1, column: 4)
            )
        )
        changes = [
            TextDocumentContentChangeEvent(
                range: nil,
                rangeLength: nil,
                text: "let b = 2"
            ),
        ]
        XCTAssertThrowsError(try Document.getTSInputEditsApplyingChanges(for: document, with: changes), "", { error in
            guard error is NilDocumentChangeRange else {
                XCTFail("Unexpected error at getTSInputEditsApplyingChanges: \(error)")
                return
            }
        })
    }
}
