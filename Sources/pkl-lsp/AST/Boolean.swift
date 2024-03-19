import Foundation
import LanguageServerProtocol

class PklBooleanLiteral: ASTNode {
    let uniqueID: UUID = .init()

    var range: ASTRange
    let importDepth: Int
    let document: Document

    var value: Bool

    var children: [any ASTNode]? = nil

    init(value: Bool, range: ASTRange, importDepth: Int, document: Document) {
        self.value = value
        self.range = range
        self.importDepth = importDepth
        self.document = document
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        nil
    }
}
