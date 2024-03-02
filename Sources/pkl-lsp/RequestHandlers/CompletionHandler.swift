import Foundation
import LanguageServerProtocol
import Logging


public class CompletionHandler {

    public let logger: Logger

    public init(logger: Logger) {
        self.logger = logger
    }

    public func provide(document: Document, module: any ASTNode, params: CompletionParams) async -> CompletionResponse {
        return nil
    }
}

enum PklKeywords : String, CaseIterable {
    case abstract
    case amends
    case `as`
    case `class`
    case `else`
    case extends
    case external
    case `false`
    case `for`
    case function
    case hidden
    case `if`
    case `import`
    case importStar = "import*"
    case `in`
    case `is`
    case `let`
    case local
    case module
    case new
    case nothing
    case null
    case open
    case out
    case outer
    case `super`
    case this
    case `throw`
    case trace
    case `true`
    case `typealias`
    case when
}

