import Foundation
import LanguageServerProtocol

enum PklStringType {
    case constant
    case singleLine
    case multiLine
}

struct PklStringLiteral: ASTNode {
    let uniqueID: UUID = .init()

    var range: ASTRange
    let importDepth: Int
    let document: Document

    var value: String?

    var type: PklStringType

    var children: [any ASTNode]? = nil

    init(value: String? = nil, type: PklStringType, range: ASTRange, importDepth: Int, document: Document) {
        self.value = value
        self.type = type
        self.range = range
        self.importDepth = importDepth
        self.document = document
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        if value != nil {
            return nil
        }
        return [ASTDiagnosticError("Provide string value", .error, range)]
    }
}
