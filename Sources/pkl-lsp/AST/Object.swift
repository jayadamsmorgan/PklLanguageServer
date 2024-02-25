import Foundation
import LanguageServerProtocol

class PklObjectBody: ASTNode {

    let uniqueID: UUID = UUID()

    var positionStart: Position
    var positionEnd: Position

    var isLeftBracePresent: Bool = false
    var isRightBracePresent: Bool = false

    var properties: [PklObjectProperty]?

    init(properties: [PklObjectProperty]?, isLeftBracePresent: Bool = false, isRightBracePresent: Bool = false, positionStart: Position, positionEnd: Position) {
        self.properties = properties
        self.positionStart = positionStart
        self.positionEnd = positionEnd
    }

    public func error() -> ASTEvaluationError? {
        if isLeftBracePresent && isRightBracePresent {
            if let properties = properties {
                for property in properties {
                    if let error = property.error() {
                        return error
                    }
                }
            }
            return nil
        }
        return nil
    }

}

class PklObjectProperty: ASTNode {

    let uniqueID: UUID = UUID()

    var positionStart: Position
    var positionEnd: Position

    var identifier: String?
    var typeAnnotation: PklTypeAnnotation?
    var value: (any ASTNode)?

    init(identifier: String? = nil, typeAnnotation: PklTypeAnnotation? = nil, value: (any ASTNode)?, positionStart: Position, positionEnd: Position) {
        self.identifier = identifier
        self.typeAnnotation = typeAnnotation
        self.value = value
        self.positionStart = positionStart
        self.positionEnd = positionEnd
    }

    public func error() -> ASTEvaluationError? {
        if identifier != nil && typeAnnotation != nil && value != nil {
            if let error = typeAnnotation?.error() {
                return error
            }
            if let error = value?.error() {
                return error
            }
            return nil
        }
        if identifier != nil && typeAnnotation != nil {
            if let error = typeAnnotation?.error() {
                return error
            }
            return ASTEvaluationError("Provide property value", positionStart, positionEnd)
        }
        if identifier != nil && value != nil {
            if let error = value?.error() {
                return error
            }
        }
        return nil
    }

}
