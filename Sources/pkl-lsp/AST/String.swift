import Foundation
import LanguageServerProtocol

enum PklStringType {
    case importString
    case constant
    case singleLine
    case multiLine
}

class PklStringLiteral: ASTNode {
    var value: String?

    var type: PklStringType

    init(value: String? = nil, type: PklStringType, range: ASTRange, importDepth: Int, document: Document) {
        self.value = value
        self.type = type
        super.init(range: range, importDepth: importDepth, document: document)
    }

    override public func diagnosticErrors() -> [ASTDiagnosticError]? {
        if value != nil {
            return nil
        }
        return [ASTDiagnosticError("Provide string value", .error, range)]
    }
}
