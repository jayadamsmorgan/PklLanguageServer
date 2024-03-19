import Foundation
import LanguageServerProtocol

enum PklIdentifierType {
    case identifier
    case qualifiedIdentifier
}

class PklIdentifier: ASTNode {
    let uniqueID: UUID = .init()

    var range: ASTRange
    let importDepth: Int
    let document: Document

    var type: PklIdentifierType

    var value: String

    var children: [any ASTNode]? = nil

    init(value: String, range: ASTRange, importDepth: Int, document: Document, type: PklIdentifierType = .identifier) {
        self.value = value
        self.range = range
        self.importDepth = importDepth
        self.document = document
        self.type = type
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        nil
    }
}
