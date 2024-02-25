import Foundation
import LanguageServerProtocol

class PklClassProperty : ASTNode {

    let uniqueID: UUID = UUID()

    var positionStart: Position
    var positionEnd: Position

    var identifier: String?
    var typeAnnotation: PklTypeAnnotation?
    var value: PklValue?
    var isHidden: Bool

    init(identifier: String? = nil, typeAnnotation: PklTypeAnnotation? = nil, value: PklValue?,
        isHidden: Bool = false, positionStart: Position, positionEnd: Position) {
        self.identifier = identifier
        self.typeAnnotation = typeAnnotation
        self.value = value
        self.isHidden = isHidden
        self.positionStart = positionStart
        self.positionEnd = positionEnd
    }

    public func error() -> ASTEvaluationError? {
        if identifier != nil && typeAnnotation != nil && value != nil {
            if let typeError = typeAnnotation?.error() {
                return typeError
            }
            if let error = value?.error() {
                return error
            }
            if value?.type?.identifier != typeAnnotation?.type?.identifier {
                return ASTEvaluationError("Property value type does not match property type", positionStart, positionEnd)
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
