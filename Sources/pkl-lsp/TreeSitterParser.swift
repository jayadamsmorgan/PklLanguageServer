import Foundation
import Logging
import LanguageServerProtocol
import SwiftTreeSitter
import TreeSitterPkl

public struct Change {
    let positionStart: Position
    let positionEnd: Position
    let oldText: String
    let newText: String
}

// The incremental parsing really stinks and works not so well yet. It's a bit of a mess. But it's a start. Don't judge.
public class TreeSitterParser {

    let logger: Logger

    let parser = Parser()
    var parsedTrees: [Document : MutableTree]

    public init(logger: Logger) {
        self.logger = logger
        let language = Language(language: tree_sitter_pkl())
        parsedTrees = [:]
        do {
            try parser.setLanguage(language)
        } catch {
            logger.debug("Failed to set language: \(error)")
            return
        }
    }

    public struct ChangeBytesError: Error {

        init(_ message: String) {
            self.message = message
        }

        let message: String
    }
    
    // Helper function to find change indices in two strings
    private func findChangeIndices(firstString: String, secondString: String) -> (firstChange: Int?, lastChangeInFirst: Int?, lastNewCharacterInSecond: Int?) {
        let firstChars = Array(firstString)
        let secondChars = Array(secondString)

        let firstChange = zip(firstChars, secondChars).enumerated().first { $1.0 != $1.1 }?.offset

        let reversedFirstChars = firstChars.reversed()
        let reversedSecondChars = secondChars.reversed()
        let lastChangeInFirst = zip(reversedFirstChars, reversedSecondChars).enumerated().first { $1.0 != $1.1 }?.offset

        let lastChangeInFirstCorrected = lastChangeInFirst != nil ? firstString.count - 1 - lastChangeInFirst! : nil

        let lastNewCharacterInSecond = secondString.isEmpty ? nil : secondString.count - 1

        return (firstChange, lastChangeInFirstCorrected, lastNewCharacterInSecond)
    }

    // Helper function to find row and column by character index in a multiline string
    func findRowAndColumn(forIndex index: Int, inString string: String) -> Point? {
        let lines = string.split(separator: "\n", omittingEmptySubsequences: false)
        var cumulativeCount = 0
        for (i, line) in lines.enumerated() {
            if cumulativeCount + line.count + 1 > index { // +1 for the newline character
                return Point(row: i, column: index - cumulativeCount)
            }
            cumulativeCount += line.count + 1
        }
        return nil
    }

    private func calculateInputEdit(
        oldText: String,
        newText: String
    ) -> InputEdit? {

        let changeIndices = findChangeIndices(firstString: oldText, secondString: newText)

        guard let firstChange = changeIndices.firstChange,
              let lastChangeInFirst = changeIndices.lastChangeInFirst,
              let lastNewCharacterInSecond = changeIndices.lastNewCharacterInSecond else {
            logger.debug("Tree-sitter parsing: Failed to calculate change indices.")
            return nil
        }

        guard let startingPoint = findRowAndColumn(forIndex: firstChange, inString: oldText),
              let oldEndingPoint = findRowAndColumn(forIndex: lastChangeInFirst, inString: oldText),
              let newEndingPoint = findRowAndColumn(forIndex: lastNewCharacterInSecond, inString: newText) else {
            logger.debug("Tree-sitter parsing: Failed to calculate row and column for change indices.")
            return nil
        }

        return InputEdit(
            startByte: firstChange,
            oldEndByte: lastChangeInFirst,
            newEndByte: lastNewCharacterInSecond,
            startPoint: startingPoint,
            oldEndPoint: oldEndingPoint,
            newEndPoint: newEndingPoint
        )
    }

    public func parseDocumentTreeSitterWithChanges(
        oldDocument: Document,
        newDocument: Document,
        previousParsingTree: MutableTree,
        changes: [TextDocumentContentChangeEvent]
    ) -> MutableTree? {
        var changesProcessed = false
        for _ in changes {
            guard let edit = calculateInputEdit(oldText: oldDocument.text, newText: newDocument.text) else {
                logger.debug("Tree-sitter parsing: Failed to calculate input edit.")
                return nil
            }
            previousParsingTree.edit(edit)
            logger.debug("Tree-sitter parsing: Edit applied: \(edit)")
            changesProcessed = true
        }
        if changesProcessed {
            logger.debug("Tree-sitter parsing: Changes processed.")
            return previousParsingTree
        }
        logger.debug("Tree-sitter parsing: No changes processed.")
        return nil
    }

    public func parseDocumentTreeSitter(newDocument: Document) -> MutableTree? {
        guard let tree = parser.parse(newDocument.text) else {
            logger.debug("Failed to tree-sitter parse complete source.")
            return nil
        }
        logger.debug("Document \(newDocument) parsed succesfully. Tree: \(tree)")
        parsedTrees[newDocument] = tree
        return tree
    }

    public func parseDocumentTreeSitter(oldDocument: Document, newDocument: Document, changes: [TextDocumentContentChangeEvent]) -> MutableTree? {
        if let previousParsingTree = parsedTrees[oldDocument] {
            if let tree = parseDocumentTreeSitterWithChanges(
                oldDocument: oldDocument,
                newDocument: newDocument,
                previousParsingTree: previousParsingTree,
                changes: changes
            ) {
                parsedTrees[oldDocument] = nil
                parsedTrees[newDocument] = tree
                return tree
            }
            logger.debug("Failed to tree-sitter parse source with changes, trying to parse whole document...")
        }

        parsedTrees[oldDocument] = nil

        return parseDocumentTreeSitter(newDocument: newDocument)
    }

}

