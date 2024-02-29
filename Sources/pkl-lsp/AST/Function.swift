import Foundation
import LanguageServerProtocol


struct PklFunctionParameter : ASTNode {
    var uniqueID: UUID = UUID()

    var positionStart: Position
    var positionEnd: Position

    var identifier: PklIdentifier?
    var typeAnnotation: PklTypeAnnotation?

    var children: [any ASTNode]? {
        var children: [any ASTNode] = []
        if identifier != nil {
            children.append(identifier!)
        }
        if typeAnnotation != nil {
            children.append(typeAnnotation!)
        }
        return children
    }

    init(identifier: PklIdentifier?, typeAnnotation: PklTypeAnnotation?, positionStart: Position, positionEnd: Position) {
        self.identifier = identifier
        self.typeAnnotation = typeAnnotation
        self.positionStart = positionStart
        self.positionEnd = positionEnd
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        var errors: [ASTDiagnosticError] = []
        if typeAnnotation != nil {
            if let typeErrors = typeAnnotation!.diagnosticErrors() {
                errors.append(contentsOf: typeErrors)
            }
        }
        if typeAnnotation == nil {
            let error = ASTDiagnosticError("Missing type annotation", .error, positionStart, positionEnd)
            errors.append(error)
        }
        if identifier == nil {
            let error = ASTDiagnosticError("Missing identifier", .error, positionStart, positionEnd)
            errors.append(error)
        }
        return errors.count > 0 ? errors : nil 
    }
}

struct PklFunctionParameterList : ASTNode {

    var uniqueID: UUID = UUID()

    var positionStart: Position
    var positionEnd: Position

    var parameters: [PklFunctionParameter]?
    var isLeftParenPresent: Bool = false
    var isRightParenPresent: Bool = false
    var commasAmount: Int = 0

    var children: [any ASTNode]? {
        var children: [any ASTNode] = []
        if parameters != nil {
            children.append(contentsOf: parameters!)
        }
        return children
    }

    init(parameters: [PklFunctionParameter]?, isLeftParenPresent: Bool = false, isRightParenPresent: Bool = false, commasAmount: Int = 0, positionStart: Position, positionEnd: Position) {
        self.parameters = parameters
        self.isLeftParenPresent = isLeftParenPresent
        self.isRightParenPresent = isRightParenPresent
        self.commasAmount = commasAmount
        self.positionStart = positionStart
        self.positionEnd = positionEnd
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        var errors: [ASTDiagnosticError] = []
        if parameters != nil {
            if parameters != nil {
                for param in parameters! {
                    if let error = param.diagnosticErrors() {
                        errors.append(contentsOf: error)
                    }
                }
            }
        }
        if parameters != nil && commasAmount != parameters!.count - 1 {
            let error = ASTDiagnosticError("Provide comma(s) between parameters", .error, positionStart, positionEnd)
            errors.append(error)
        }
        if !isLeftParenPresent {
            let error = ASTDiagnosticError("Provide left parenthesis", .error, positionStart, positionEnd)
            errors.append(error)
        }
        if !isRightParenPresent {
            let error = ASTDiagnosticError("Provide right parenthesis", .error, positionStart, positionEnd)
            errors.append(error)
        }
        return errors.count > 0 ? errors : nil
    }
}

struct PklFunctionDeclaration : ASTNode {

    let uniqueID: UUID = UUID()

    var positionStart: Position
    var positionEnd: Position

    var body: PklClassFunctionBody?
    var functionValue: (any ASTNode)?

    var children: [any ASTNode]? {
        var children: [any ASTNode] = []
        if body != nil {
            children.append(body!)
        }
        if functionValue != nil {
            children.append(functionValue!)
        }
        return children
    }

    init(body: PklClassFunctionBody?, functionValue: (any ASTNode)?, positionStart: Position, positionEnd: Position) {
        self.body = body
        self.functionValue = functionValue
        self.positionStart = positionStart
        self.positionEnd = positionEnd
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        var errors: [ASTDiagnosticError] = []
        if body != nil {
            if let bodyErrors = body?.diagnosticErrors() {
                errors.append(contentsOf: bodyErrors)
            }
        }
        if body == nil {
            let error = ASTDiagnosticError("Provide function body", .error, positionStart, positionEnd)
            errors.append(error)
        }
        if functionValue != nil {
            if let valueErrors = functionValue?.diagnosticErrors() {
                errors.append(contentsOf: valueErrors)
            }
        }
        if functionValue == nil {
            let error = ASTDiagnosticError("Provide function value", .error, positionStart, positionEnd)
            errors.append(error)
        }
        return errors.count > 0 ? errors : nil
    }
}

struct PklClassFunctionBody : ASTNode {

    let uniqueID: UUID = UUID()

    var positionStart: Position
    var positionEnd: Position

    var isFunctionKeywordPresent: Bool = false
    var identifier: PklIdentifier?
    var params: PklFunctionParameterList?
    var typeAnnotation: PklTypeAnnotation?

    var children: [any ASTNode]? {
        var children: [any ASTNode] = []
        if identifier != nil {
            children.append(identifier!)
        }
        if params != nil {
            children.append(params!)
        }
        if typeAnnotation != nil {
            children.append(typeAnnotation!)
        }
        return children
    }

    init(isFunctionKeywordPresent: Bool = false, identifier: PklIdentifier?, params: PklFunctionParameterList?, typeAnnotation: PklTypeAnnotation? = nil,
        positionStart: Position, positionEnd: Position) {
        self.isFunctionKeywordPresent = isFunctionKeywordPresent
        self.identifier = identifier
        self.params = params
        self.positionStart = positionStart
        self.positionEnd = positionEnd
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        var errors: [ASTDiagnosticError] = []
        if !isFunctionKeywordPresent {
            let error = ASTDiagnosticError("Provide function keyword", .error, positionStart, positionEnd)
            errors.append(error)
        }
        if typeAnnotation != nil {
            if let typeErrors = typeAnnotation?.diagnosticErrors() {
                errors.append(contentsOf: typeErrors)
            }
        }
        if typeAnnotation == nil {
            let error = ASTDiagnosticError("Provide function type annotation", .error, positionStart, positionEnd)
            errors.append(error)
        }
        if identifier == nil {
            let error = ASTDiagnosticError("Provide function identifier", .error, positionStart, positionEnd)
            errors.append(error)
        }
        return errors.count > 0 ? errors : nil
    }

}

