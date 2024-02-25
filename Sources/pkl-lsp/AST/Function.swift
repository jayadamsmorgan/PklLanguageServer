import Foundation
import LanguageServerProtocol


class PklFunctionParameter : ASTNode {
    var uniqueID: UUID = UUID()

    var positionStart: Position
    var positionEnd: Position

    var identifier: String?
    var typeAnnotation: PklTypeAnnotation?

    init(identifier: String?, typeAnnotation: PklTypeAnnotation?, positionStart: Position, positionEnd: Position) {
        self.identifier = identifier
        self.typeAnnotation = typeAnnotation
        self.positionStart = positionStart
        self.positionEnd = positionEnd
    }

    public func error() -> ASTEvaluationError? {
        if typeAnnotation != nil {
            return typeAnnotation!.error()
        }
        if identifier == nil {
            return ASTEvaluationError("Missing identifier", positionStart, positionEnd)
        }
        return nil
    }
}

class PklFunctionParameterList : ASTNode {

    var uniqueID: UUID = UUID()

    var positionStart: Position
    var positionEnd: Position

    var parameters: [PklFunctionParameter]?
    var isLeftParenPresent: Bool = false
    var isRightParenPresent: Bool = false
    var commasAmount: Int = 0

    init(parameters: [PklFunctionParameter]?, isLeftParenPresent: Bool = false, isRightParenPresent: Bool = false, commasAmount: Int = 0, positionStart: Position, positionEnd: Position) {
        self.parameters = parameters
        self.isLeftParenPresent = isLeftParenPresent
        self.isRightParenPresent = isRightParenPresent
        self.commasAmount = commasAmount
        self.positionStart = positionStart
        self.positionEnd = positionEnd
    }

    public func error() -> ASTEvaluationError? {
        if isLeftParenPresent && isRightParenPresent && parameters != nil && commasAmount == parameters!.count - 1 {
            if parameters != nil {
                for param in parameters! {
                    if let error = param.error() {
                        return error
                    }
                }
                return nil
            }
            return ASTEvaluationError("Provide function parameters", positionStart, positionEnd)
        }
        if isLeftParenPresent && isRightParenPresent && parameters != nil && commasAmount != parameters!.count - 1 {
            return ASTEvaluationError("Provide commas between parameters", positionStart, positionEnd)
        }
        if !isLeftParenPresent {
            return ASTEvaluationError("Provide left parenthesis", positionStart, positionEnd)
        }
        return ASTEvaluationError("Provide right parenthesis", positionStart, positionEnd)
    }
}

class PklFunctionDeclaration: ASTNode {

    let uniqueID: UUID = UUID()

    var positionStart: Position
    var positionEnd: Position

    var body: PklClassFunctionBody?
    var functionValue: (any ASTNode)?

    init(body: PklClassFunctionBody?, functionValue: (any ASTNode)?, positionStart: Position, positionEnd: Position) {
        self.body = body
        self.functionValue = functionValue
        self.positionStart = positionStart
        self.positionEnd = positionEnd
    }

    public func error() -> ASTEvaluationError? {
        if body != nil && functionValue != nil {
            return body?.error()
        }
        if body == nil {
            return ASTEvaluationError("Provide function body", positionStart, positionEnd)
        }
        return ASTEvaluationError("Provide function value", positionStart, positionEnd)
    }
}

class PklClassFunctionBody: ASTNode {

    let uniqueID: UUID = UUID()

    var positionStart: Position
    var positionEnd: Position

    var isFunctionKeywordPresent: Bool = false
    var identifier: String?
    var params: PklFunctionParameterList?

    init(isFunctionKeywordPresent: Bool = false, identifier: String?, params: PklFunctionParameterList?, positionStart: Position, positionEnd: Position) {
        self.isFunctionKeywordPresent = isFunctionKeywordPresent
        self.identifier = identifier
        self.params = params
        self.positionStart = positionStart
        self.positionEnd = positionEnd
    }

    public func error() -> ASTEvaluationError? {
        if isFunctionKeywordPresent && identifier != nil && params != nil {
            return params?.error()
        }
        if identifier == nil {
            return ASTEvaluationError("Provide function identifier", positionStart, positionEnd)
        }
        if !isFunctionKeywordPresent {
            return ASTEvaluationError("Provide function keyword", positionStart, positionEnd)
        }
        return nil
    }

}
