import Foundation
import LanguageServerProtocol
import Logging


public class DocumentSymbolsHandler {

    public let logger: Logger

    public init(logger: Logger) {
        self.logger = logger
    }

    public func provide(document: Document, module: any ASTNode, params: DocumentSymbolParams) async -> DocumentSymbolResponse {
        return nil
    }

}

