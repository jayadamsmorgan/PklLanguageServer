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

struct PklNumberLiteral : ASTNode {

    let uniqueID: UUID = UUID()

    var positionStart: Position
    var positionEnd: Position

    var value: String?
    var type: PklNumberType
    
    init(value: String? = nil, type: PklNumberType, positionStart: Position, positionEnd: Position) {
        self.value = value
        self.type = type
        self.positionStart = positionStart
        self.positionEnd = positionEnd
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        if value != nil {
            return nil
        }
        return [ASTDiagnosticError("Provide number value", .error, positionStart, positionEnd)]
    }
}

