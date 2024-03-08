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

        guard let context = positionContext else {
            logger.debug("DefinitionHandler: Position context is nil.")
            return nil
        }
        logger.debug("DefinitionHandler: Position context: \(context)")

        if let context = context as? PklStringLiteral {
            if context.type == .importString {
                logger.debug("DefinitionHandler: Trying to find imported module.")
                var relPath = context.value ?? ""
                relPath.removeAll(where: { $0 == "\"" })
                let modulePath = URL(fileURLWithPath: document.uri)
                    .deletingLastPathComponent()
                    .appendingPathComponent(relPath)
                    .standardized
                do {
                    guard try modulePath.checkResourceIsReachable() else {
                        logger.debug("DefinitionHandler: Module at path \(modulePath.absoluteString) is not reachable.")
                        return nil
                    }
                    logger.debug("DefinitionHandler: Module at path \(modulePath.absoluteString) found.")
                    return .optionA(Location(uri: modulePath.absoluteString, range: LSPRange.zero))
                } catch {
                    logger.debug("DefinitionHandler: Unable to check if module exists: \(error)")
                    return nil
                }
            }
        }

        let allNodes = ASTHelper.allNodes(node: module)
        let parentNode = allNodes.first(where: { node in
            node.children?.contains(where: { child in
                child.uniqueID == context.uniqueID
            }) ?? false
        })
        guard let parent = parentNode else {
            let range = context.range.getLSPRange()
            return .optionA(Location(uri: document.uri, range: range))
        }
        logger.debug("DefinitionHandler: Parent node: \(String(describing: parent))")

        let range = context.range.getLSPRange()
        return .optionA(Location(uri: document.uri, range: range))
    }
}
