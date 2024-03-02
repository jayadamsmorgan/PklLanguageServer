import Foundation
import LanguageServerProtocol
import Logging


public class DefinitionHandler {

    public let logger: Logger

    public init(logger: Logger) {
        self.logger = logger
    }

    public func provide(document: Document, module: any ASTNode, params: TextDocumentPositionParams) async -> DefinitionResponse {
        return nil
    }

}

