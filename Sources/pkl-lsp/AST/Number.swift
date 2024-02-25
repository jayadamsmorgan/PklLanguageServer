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

class PklNumberLiteral : ASTNode {

    let uniqueID: UUID = UUID()

    var positionStart: Position
    var positionEnd: Position

    var value: String?
    var type: PklNumberType?
    
    init(value: String? = nil, positionStart: Position, positionEnd: Position) {
        self.value = value
        self.positionStart = positionStart
        self.positionEnd = positionEnd
    }

    public func error() -> ASTEvaluationError? {
        if value != nil {
            return nil
        }
        return ASTEvaluationError("Provide number value", positionStart, positionEnd)
    }
}

