import Foundation
import LanguageServerProtocol

enum PklNumberType {
    case int
    case uint
    case float
    case int8
    case int16
    case int32
    case uint8
    case uint16
    case uint32
}

class PklNumberLiteral: ASTNode {
    var value: String?
    var type: PklNumberType

    init(value: String? = nil, type: PklNumberType, range: ASTRange, importDepth: Int, document: Document) {
        self.value = value
        self.type = type
        super.init(range: range, importDepth: importDepth, document: document)
    }

    override public func diagnosticErrors() -> [ASTDiagnosticError]? {
        if value != nil {
            return nil
        }
        return [ASTDiagnosticError("Provide number value", .error, range)]
    }
}
