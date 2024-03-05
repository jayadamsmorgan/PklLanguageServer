import Foundation
import LanguageServerProtocol

struct PklBooleanLiteral: ASTNode {
    let uniqueID: UUID = .init()

    var range: ASTRange

    var value: Bool

    var children: [any ASTNode]? = nil

    init(value: Bool, range: ASTRange) {
        self.value = value
        self.range = range
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        nil
    }
}
