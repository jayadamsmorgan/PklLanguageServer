import Foundation
import LanguageServerProtocol

struct PklNullLiteral: ASTNode {
    let uniqueID: UUID = .init()

    var range: ASTRange

    var children: [any ASTNode]? = nil

    init(range: ASTRange) {
        self.range = range
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        nil
    }
}
