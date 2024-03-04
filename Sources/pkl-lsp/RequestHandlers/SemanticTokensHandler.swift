import Foundation
import LanguageServerProtocol
import Logging

public class SemanticTokensHandler {
    public let logger: Logger

    public init(logger: Logger) {
        self.logger = logger
    }

    public func provide(document _: Document, module _: any ASTNode, params _: SemanticTokensParams) async -> SemanticTokensResponse {
        nil
    }
}
