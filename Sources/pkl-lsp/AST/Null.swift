import Foundation
import LanguageServerProtocol

struct PklNullLiteral: ASTNode {
    let uniqueID: UUID = .init()

    var range: ASTRange
    let importDepth: Int

    var children: [any ASTNode]? = nil

    init(range: ASTRange, importDepth: Int) {
        self.range = range
        self.importDepth = importDepth
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        nil
    }
}
