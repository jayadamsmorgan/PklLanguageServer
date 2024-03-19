import Foundation
import LanguageServerProtocol

class PklNullLiteral: ASTNode {
    let uniqueID: UUID = .init()

    var range: ASTRange
    let importDepth: Int
    let document: Document

    var children: [any ASTNode]? = nil

    init(range: ASTRange, importDepth: Int, document: Document) {
        self.range = range
        self.importDepth = importDepth
        self.document = document
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        nil
    }
}
