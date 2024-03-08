import Foundation
import LanguageServerProtocol

struct PklIdentifier: ASTNode {
    let uniqueID: UUID = .init()

    var range: ASTRange
    let importDepth: Int
    let document: Document

    var value: String

    var children: [any ASTNode]? = nil

    init(value: String, range: ASTRange, importDepth: Int, document: Document) {
        self.value = value
        self.range = range
        self.importDepth = importDepth
        self.document = document
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        nil
    }
}
