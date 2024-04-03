import Foundation
import LanguageServerProtocol
import Logging

public class DefinitionHandler {
    public let logger: Logger

    public init(logger: Logger) {
        self.logger = logger
    }

    public func provide(module: ASTNode, params: TextDocumentPositionParams) async -> DefinitionResponse {
        let positionContext = ASTHelper.getPositionContext(module: module, position: params.position)

        guard let context = positionContext else {
            logger.debug("DefinitionHandler: Position context is nil.")
            return nil
        }
        logger.debug("DefinitionHandler: Position context: \(context)")

        if let context = context as? PklStringLiteral {
            if context.type == .importString {
                return await provideForModuleImport(path: context)
            }
            return nil
        }
        if let context = context as? PklModuleImport {
            return await provideForModuleImport(path: context.path)
        }

        if let context = context as? PklVariable {
            logger.debug("DefinitionHandler: Searching for definition of variable \(context.identifier?.value ?? "nil")")
            guard let reference = context.reference else {
                logger.debug("DefinitionHandler: Variable reference is nil.")
                return nil
            }
            return .optionA(Location(uri: reference.document.uri, range: reference.range.getLSPRange()))
        }

        return nil
    }

    private func provideForModuleImport(path: PklStringLiteral) async -> DefinitionResponse {
        logger.debug("DefinitionHandler: Trying to find imported module.")
        var relPath = path.value ?? ""
        relPath.removeAll(where: { $0 == "\"" })
        let modulePath = URL(fileURLWithPath: path.document.uri)
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
