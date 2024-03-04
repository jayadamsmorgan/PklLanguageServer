import Foundation
import LanguageServerProtocol
import Logging

public class DefinitionHandler {
    public let logger: Logger

    public init(logger: Logger) {
        self.logger = logger
    }

    public func provide(document: Document, module: any ASTNode, params: TextDocumentPositionParams) async -> DefinitionResponse {
        let postionContext = ASTHelper.getPositionContext(module: module, position: params.position)
        logger.debug("Position context: \(String(describing: postionContext))")
        if let context = postionContext {
            return DefinitionResponse(.optionA(Location(uri: document.uri, range: LSPRange(start: context.positionStart, end: context.positionEnd))))
        }
        return nil
    }
}
