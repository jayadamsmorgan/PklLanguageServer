import Foundation
import LanguageServerProtocol

struct PklBooleanLiteral: ASTNode {
    let uniqueID: UUID = .init()

    var range: ASTRange
    let importDepth: Int

    var value: Bool

    var children: [any ASTNode]? = nil

    init(value: Bool, range: ASTRange, importDepth: Int) {
        self.value = value
        self.range = range
        self.importDepth = importDepth
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        nil
    }
}
