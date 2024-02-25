import Foundation
import LanguageServerProtocol

public enum PklStandardTypesIdentifiers : String, CaseIterable {
    case Number
    case Int
    case Float
    case String
}

class PklType : ASTNode {

    let uniqueID: UUID = UUID()

    var positionStart: Position
    var positionEnd: Position

    var identifier: String?

    init(identifier: String? = nil, positionStart: Position, positionEnd: Position) {
        self.identifier = identifier
        self.positionStart = positionStart
        self.positionEnd = positionEnd
    }

    public func error() -> ASTEvaluationError? {
        if identifier != nil {
            return nil
        }
        return ASTEvaluationError("Provide type identifier", positionStart, positionEnd)
    }
}

class PklTypeAnnotation : ASTNode {

    let uniqueID: UUID = UUID()

    var positionStart: Position
    var positionEnd: Position
    
    var type: PklType?
    var colonIsPresent: Bool = false

    init(type: PklType? = nil, colonIsPresent: Bool = false, positionStart: Position, positionEnd: Position) {
        self.type = type
        self.colonIsPresent = colonIsPresent
        self.positionStart = positionStart
        self.positionEnd = positionEnd
    }

    public func error() -> ASTEvaluationError? {
        if (type != nil && colonIsPresent) {
            return type?.error()
        }
        if type == nil {
            return ASTEvaluationError("Provide type identifier", positionStart, positionEnd)
        }
        return ASTEvaluationError("Missing colon symbol before type identifier", positionStart, positionEnd)
    }

}

