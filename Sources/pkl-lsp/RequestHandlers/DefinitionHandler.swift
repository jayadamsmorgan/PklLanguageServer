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
        if let context = positionContext {
            if let context = context as? PklStringLiteral {
                if context.type == .importString {
                    logger.debug("DefinitionHandler: Trying to find imported module.")
                    var relPath = context.value ?? ""
                    relPath.removeAll(where: { $0 == "\"" })
                    let modulePath = URL(fileURLWithPath: document.uri)
                        .deletingLastPathComponent()
                        .appendingPathComponent(relPath)
                    return .optionA(Location(uri: modulePath.absoluteString, range: LSPRange.zero))
                }
            }
            let range = context.range.getLSPRange()
            return .optionA(Location(uri: document.uri, range: range))
        }
        return nil
    }
}
