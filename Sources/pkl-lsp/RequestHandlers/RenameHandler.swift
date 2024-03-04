import Foundation
import LanguageServerProtocol
import Logging

public class RenameHandler {
    public let logger: Logger

    public init(logger: Logger) {
        self.logger = logger
    }

    public func provide(document _: Document, module: any ASTNode, params: RenameParams) async -> RenameResponse {
        var identifiers: [PklIdentifier] = ASTHelper.getASTIdentifiers(node: module)
        logger.debug("LSP Rename: Found \(identifiers) identifiers in \(params.textDocument.uri).")

        // Character position is doubled after tree-siiter parsing due to UTF16 (I guess), so we need to divide it by 2
        // I don't really like this solution, but it works for now
        // Not sure if it's also a good idea to divide it by 2 at AST initialization, need to think about it
        let positionIdentifier: PklIdentifier? = identifiers.first(where: {
            $0.positionStart.line == params.position.line &&
                $0.positionStart.character / 2 <= params.position.character &&
                $0.positionEnd.character / 2 >= params.position.character
        })
        guard let positionIdentifier else {
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
