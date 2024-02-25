import Foundation
import LanguageServerProtocol

class PklClassProperty : ASTNode {

    let uniqueID: UUID = UUID()

    var positionStart: Position
    var positionEnd: Position

    var identifier: String?
    var typeAnnotation: PklTypeAnnotation?
    var isEqualsPresent: Bool = false
    var value: (any ASTNode)?
    var isHidden: Bool

    init(identifier: String? = nil, typeAnnotation: PklTypeAnnotation? = nil, isEqualsPresent: Bool = false, value: (any ASTNode)?,
        isHidden: Bool = false, positionStart: Position, positionEnd: Position) {
        self.identifier = identifier
        self.typeAnnotation = typeAnnotation
        self.isEqualsPresent = isEqualsPresent
        self.value = value
        self.isHidden = isHidden
        self.positionStart = positionStart
        self.positionEnd = positionEnd
    }

    public func error() -> ASTEvaluationError? {
        if identifier != nil && typeAnnotation != nil && isEqualsPresent && value != nil {
            if let typeError = typeAnnotation?.error() {
                return typeError
            }
            if let error = value?.error() {
                return error
            }
            if let value = value as? PklValue {
                if value.type?.identifier != typeAnnotation?.type?.identifier {
                    return ASTEvaluationError("Property value type does not match property type", positionStart, positionEnd)
                }
            }
            if let value = value as? PklObjectBody {
                // TODO: Check if object body type matches property type
                return ASTEvaluationError("Object body type checking is not implemented yet", positionStart, positionEnd)
            }
            return nil
        }
        if identifier != nil && typeAnnotation != nil {
            return typeAnnotation?.error()
        }
        if identifier != nil && value != nil {
            return value?.error()
        }
        if identifier != nil {
            return ASTEvaluationError("Provide property type or value", positionStart, positionEnd)
        }
        return ASTEvaluationError("Provide property identifier", positionStart, positionEnd)
    }
}

class PklClass : ASTNode {

    let uniqueID: UUID = UUID()

    var positionStart: Position
    var positionEnd: Position

    var properties: [PklClassProperty]?
    var functions: [PklFunctionDeclaration]?

    var leftBraceIsPresent: Bool = false
    var rightBraceIsPresent: Bool = false

    init(properties: [PklClassProperty]? = nil, functions: [PklFunctionDeclaration]? = nil, leftBraceIsPresent: Bool = false, rightBraceIsPresent: Bool = false,
        positionStart: Position, positionEnd: Position) {
        self.properties = properties
        self.leftBraceIsPresent = leftBraceIsPresent
        self.rightBraceIsPresent = rightBraceIsPresent
        self.positionStart = positionStart
        self.positionEnd = positionEnd
    }

    public func error() -> ASTEvaluationError? {
        if properties != nil && leftBraceIsPresent && rightBraceIsPresent {
            for property in properties! {
                if let error = property.error() {
                    return error
                }
            }
            return nil
        }
        if properties == nil {
            return ASTEvaluationError("Provide class body", positionStart, positionEnd)
        }
        if !leftBraceIsPresent {
            return ASTEvaluationError("Missing left brace symbol", positionStart, positionEnd)
        }
        return ASTEvaluationError("Missing right brace symbol", positionStart, positionEnd)
    }
}

class PklClassDeclaration : ASTNode {

    let uniqueID: UUID = UUID()

    var positionStart: Position
    var positionEnd: Position

    var classNode: PklClass?
    var classKeyword: String?
    var classIdentifier: String?

    init(classNode: PklClass? = nil, classKeyword: String? = nil, classIdentifier: String? = nil, positionStart: Position, positionEnd: Position) {
        self.classNode = classNode
        self.classKeyword = classKeyword
        self.classIdentifier = classIdentifier
        self.positionStart = positionStart
        self.positionEnd = positionEnd
    }

    public func error() -> ASTEvaluationError? {
        if classNode != nil && classKeyword == "class" && classIdentifier != nil {
            return classNode?.error()
        }
        if classKeyword != "class" {
            return ASTEvaluationError("Missing class keyword", positionStart, positionEnd)
        }
        if classIdentifier == nil {
            return ASTEvaluationError("Provide class identifier", positionStart, positionEnd)
        }
        return ASTEvaluationError("Provide class body", positionStart, positionEnd)
    }

}
