import Foundation
import LanguageServerProtocol
import Logging

public class DefinitionHandler {
    public let logger: Logger

    public init(logger: Logger) {
        self.logger = logger
    }

    public func provide(document: Document, module: any ASTNode, params: TextDocumentPositionParams) async -> DefinitionResponse {
        let positionContext = ASTHelper.getPositionContext(module: module, position: params.position)
        logger.debug("Position context: \(String(describing: positionContext))")
        let endNodes = ASTHelper.allNodes(node: module)
        for node in endNodes {
            logger.debug("Found end node: \(node)")
        }
        if let context = positionContext {
            return DefinitionResponse(.optionA(Location(uri: document.uri, range: context.range.getLSPRange())))
        }
        return nil
    }
}
