import Foundation
import LanguageServerProtocol
import Logging


public class SemanticTokensHandler {

    public let logger: Logger

    public init(logger: Logger) {
        self.logger = logger
    }

    public func provide(document: Document, module: any ASTNode, params: SemanticTokensParams) async -> SemanticTokensResponse {
        return nil
    }

}

