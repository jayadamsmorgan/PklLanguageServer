import Foundation
import LanguageServerProtocol
@testable import pkl_lsp
import SwiftTreeSitter
import XCTest

class DocumentTests: XCTestCase {
    let document = Document(uri: "file:///test.pkl", version: 0,
                            text: """
                            let a = 1
                            let b = 2
                            let c = 3
                            """)

    public func testApplyingChangesWhenChangesPresentAndValid() async throws {
        var document = document
        let changes = [
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
    }

    public func testApplyingChangesWhenChangesPresentAndInvalid() async throws {
        let document = document
        let changes = [
            TextDocumentContentChangeEvent(
                range: LSPRange(start: Position(line: 5, character: 4), end: Position(line: 3, character: 3)),
                rangeLength: nil,
                text: ""
            ),
        ]
        XCTAssertThrowsError(try document.withAppliedChanges(changes, nextVersion: nil), "") { error in
            guard error is DocumentError else {
                XCTFail("Unexpected error at withAppliedChanges: \(error)")
                return
            }
        }
    }

    public func testApplyingChangesWhenChangesNil() async throws {
        var document = document
        var changes = [
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

    public func testFindPositionWhenPositionValid() async throws {
        let index = try Document.findPosition(Position((2, 4)), in: document.text)
        XCTAssertEqual(index?.utf16Offset(in: document.text), 24)
    }

    public func testFindPositionWhenPositionInvalid() async throws {
        let index = try Document.findPosition(Position((4, 5)), in: document.text)
        XCTAssertEqual(index, nil)
    }

    public func testGetTSInputEditsApplyingChangesWhenChangesPresentAndValid() async throws {
        let document = document
        let changes = [
            TextDocumentContentChangeEvent(
                range: .init(start: .init((0, 4)), end: .init((0, 5))),
                rangeLength: nil,
                text: "b"
            ),
            TextDocumentContentChangeEvent(
                range: .init(start: .init((1, 4)), end: .init((2, 5))),
                rangeLength: nil,
                text: ""
            ),
        ]
        let edits = try Document.getTSInputEditsApplyingChanges(for: document, with: changes, nextVersion: 1)
        XCTAssertEqual(edits.document.text, """
        let b = 1
        let  = 3
        """)
        XCTAssertEqual(edits.inputEdits.count, 2)
        XCTAssertEqual(
            edits.inputEdits[0],
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
            edits.inputEdits[1],
            InputEdit(
                startByte: 28,
                oldEndByte: 50,
                newEndByte: 28,
                startPoint: Point(row: 1, column: 4),
                oldEndPoint: Point(row: 2, column: 5),
                newEndPoint: Point(row: 1, column: 4)
            )
        )
    }

    public func testGetTSInputEditsApplyingChangesWhenChangesPresentAndInvalid() async throws {
        let document = document
        let changes = [
            TextDocumentContentChangeEvent(
                range: .init(start: .init((5, 4)), end: .init((3, 3))),
                rangeLength: nil,
                text: ""
            ),
        ]
        XCTAssertThrowsError(try Document.getTSInputEditsApplyingChanges(for: document, with: changes), "") { error in
            guard error is DocumentError else {
                XCTFail("Unexpected error at getTSInputEditsApplyingChanges: \(error)")
                return
            }
        }
    }

    public func testGetTSInputEditsApplyingChangesWhenChangeRangeNil() async throws {
        let document = document
        let changes = [
            TextDocumentContentChangeEvent(
                range: nil,
                rangeLength: nil,
                text: "let b = 2"
            ),
        ]
        XCTAssertThrowsError(try Document.getTSInputEditsApplyingChanges(for: document, with: changes), "") { error in
            guard error is DocumentError else {
                XCTFail("Unexpected error at getTSInputEditsApplyingChanges: \(error)")
                return
            }
        }
    }
}
