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

struct PklNumberLiteral: ASTNode {
    let uniqueID: UUID = .init()

    var range: ASTRange

    var value: String?
    var type: PklNumberType

    var children: [any ASTNode]? = nil

    init(value: String? = nil, type: PklNumberType, range: ASTRange) {
        self.value = value
        self.type = type
        self.range = range
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        if value != nil {
            return nil
        }
        return [ASTDiagnosticError("Provide number value", .error, range)]
    }
}
