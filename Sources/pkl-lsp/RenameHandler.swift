import Foundation
import LanguageServerProtocol
import Logging

public class RenameHandler {

    public let logger: Logger

    public init(logger: Logger) {
        self.logger = logger
    }

    private func getASTIdentifiers(node: any ASTNode, identifiers: inout [PklIdentifier]) {
        if let children = node.children {
            for child in children {
                if let identifier = child as? PklIdentifier {
                    identifiers.append(identifier)
                }
                getASTIdentifiers(node: child, identifiers: &identifiers)
            }
        }
    }

    public func rename(document: Document, module: any ASTNode, params: RenameParams) async -> WorkspaceEdit? {
        var identifiers: [PklIdentifier] = []
        getASTIdentifiers(node: module, identifiers: &identifiers)
        logger.debug("LSP Rename: Found \(identifiers) identifiers in \(params.textDocument.uri).")
        let positionIdentifier: PklIdentifier? = identifiers.first(where: {
            $0.positionStart.line == params.position.line &&
            $0.positionStart.character / 2 <= params.position.character &&
            $0.positionEnd.character / 2 >= params.position.character
        })
        guard let positionIdentifier = positionIdentifier else {
            logger.debug("LSP Rename: No identifier found at position \(params.position) in \(params.textDocument.uri).")
            return nil
        }
        logger.debug("LSP Rename: Found identifier \(positionIdentifier.value) at position \(params.position) in \(params.textDocument.uri).")
        identifiers = identifiers.filter { $0.value == positionIdentifier.value }
        var changes: [TextEdit] = []
        for identifier in identifiers {
            let positionStart = Position(line: identifier.positionStart.line, character: identifier.positionStart.character / 2)
            let positionEnd = Position(line: identifier.positionEnd.line, character: identifier.positionEnd.character / 2)
            let edit = TextEdit(range: LSPRange(start: positionStart, end: positionEnd), newText: params.newName)
            changes.append(edit)
        }
        return WorkspaceEdit(changes: [params.textDocument.uri: changes])
    }
}
