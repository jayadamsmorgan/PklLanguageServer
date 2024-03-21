import Foundation
import LanguageServerProtocol

class PklFunctionParameter: ASTNode {
    var uniqueID: UUID = .init()

    var range: ASTRange
    let importDepth: Int
    let document: Document

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

    init(identifier: PklIdentifier?, typeAnnotation: PklTypeAnnotation?, range: ASTRange, importDepth: Int, document: Document) {
        self.identifier = identifier
        self.typeAnnotation = typeAnnotation
        self.range = range
        self.importDepth = importDepth
        self.document = document
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        var errors: [ASTDiagnosticError] = []
        if typeAnnotation != nil {
            if let typeErrors = typeAnnotation!.diagnosticErrors() {
                errors.append(contentsOf: typeErrors)
            }
        }
        if typeAnnotation == nil {
            let error = ASTDiagnosticError("Missing type annotation", .error, range)
            errors.append(error)
        }
        if identifier == nil {
            let error = ASTDiagnosticError("Missing identifier", .error, range)
            errors.append(error)
        }
        return errors.count > 0 ? errors : nil
    }
}

class PklFunctionParameterList: ASTNode {
    var uniqueID: UUID = .init()

    var range: ASTRange
    let importDepth: Int
    let document: Document

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

    init(parameters: [PklFunctionParameter]?, isLeftParenPresent: Bool = false, isRightParenPresent: Bool = false,
         commasAmount: Int = 0, range: ASTRange, importDepth: Int, document: Document)
    {
        self.parameters = parameters
        self.isLeftParenPresent = isLeftParenPresent
        self.isRightParenPresent = isRightParenPresent
        self.commasAmount = commasAmount
        self.range = range
        self.importDepth = importDepth
        self.document = document
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
        if parameters != nil, commasAmount != parameters!.count - 1 {
            let error = ASTDiagnosticError("Provide comma(s) between parameters", .error, range)
            errors.append(error)
        }
        if !isLeftParenPresent {
            let error = ASTDiagnosticError("Provide left parenthesis", .error, range)
            errors.append(error)
        }
        if !isRightParenPresent {
            let error = ASTDiagnosticError("Provide right parenthesis", .error, range)
            errors.append(error)
        }
        return errors.count > 0 ? errors : nil
    }
}

class PklFunctionDeclaration: ASTNode {
    let uniqueID: UUID = .init()

    var range: ASTRange
    let importDepth: Int
    let document: Document

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

    init(body: PklClassFunctionBody?, functionValue: (any ASTNode)?, range: ASTRange, importDepth: Int, document: Document) {
        self.body = body
        self.functionValue = functionValue
        self.range = range
        self.importDepth = importDepth
        self.document = document
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        var errors: [ASTDiagnosticError] = []
        if body != nil {
            if let bodyErrors = body?.diagnosticErrors() {
                errors.append(contentsOf: bodyErrors)
            }
        }
        if body == nil {
            let error = ASTDiagnosticError("Provide function body", .error, range)
            errors.append(error)
        }
        if functionValue != nil {
            if let valueErrors = functionValue?.diagnosticErrors() {
                errors.append(contentsOf: valueErrors)
            }
        }
        if functionValue == nil {
            let error = ASTDiagnosticError("Provide function value", .error, range)
            errors.append(error)
        }
        return errors.count > 0 ? errors : nil
    }
}

class PklClassFunctionBody: ASTNode {
    let uniqueID: UUID = .init()

    var range: ASTRange
    let importDepth: Int
    let document: Document

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

    init(isFunctionKeywordPresent: Bool = false, identifier: PklIdentifier?, params: PklFunctionParameterList?,
         typeAnnotation _: PklTypeAnnotation? = nil, range: ASTRange, importDepth: Int, document: Document)
    {
        self.isFunctionKeywordPresent = isFunctionKeywordPresent
        self.identifier = identifier
        self.params = params
        self.range = range
        self.importDepth = importDepth
        self.document = document
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        var errors: [ASTDiagnosticError] = []
        if !isFunctionKeywordPresent {
            let error = ASTDiagnosticError("Provide function keyword", .error, range)
            errors.append(error)
        }
        if typeAnnotation != nil {
            if let typeErrors = typeAnnotation?.diagnosticErrors() {
                errors.append(contentsOf: typeErrors)
            }
        }
        if typeAnnotation == nil {
            let error = ASTDiagnosticError("Provide function type annotation", .error, range)
            errors.append(error)
        }
        if identifier == nil {
            let error = ASTDiagnosticError("Provide function identifier", .error, range)
            errors.append(error)
        }
        return errors.count > 0 ? errors : nil
    }
}

class PklMethodParameter: ASTNode {
    let uniqueID: UUID = .init()

    var range: ASTRange
    let importDepth: Int
    let document: Document

    var value: (any ASTNode)?

    var children: [any ASTNode]? {
        var children: [any ASTNode] = []
        if let value {
            children.append(value)
        }
        return children
    }

    init(value: (any ASTNode)?, range: ASTRange, importDepth: Int, document: Document) {
        self.value = value
        self.range = range
        self.importDepth = importDepth
        self.document = document
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        var errors: [ASTDiagnosticError] = []
        if value == nil {
            let error = ASTDiagnosticError("Provide method parameter value", .error, range)
            errors.append(error)
        }
        return errors.count > 0 ? errors : nil
    }
}

class PklMethodParameterList: ASTNode {
    let uniqueID: UUID = .init()

    var range: ASTRange
    let importDepth: Int
    let document: Document

    var parameters: [PklMethodParameter]?
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

    init(parameters: [PklMethodParameter]?, isLeftParenPresent: Bool = false, isRightParenPresent: Bool = false,
         commasAmount: Int = 0, range: ASTRange, importDepth: Int, document: Document)
    {
        self.parameters = parameters
        self.isLeftParenPresent = isLeftParenPresent
        self.isRightParenPresent = isRightParenPresent
        self.commasAmount = commasAmount
        self.range = range
        self.importDepth = importDepth
        self.document = document
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        var errors: [ASTDiagnosticError] = []
        if parameters != nil {
            for param in parameters! {
                if let error = param.diagnosticErrors() {
                    errors.append(contentsOf: error)
                }
            }
        }
        if parameters != nil, commasAmount != parameters!.count - 1 {
            let error = ASTDiagnosticError("Provide comma(s) between parameters", .error, range)
            errors.append(error)
        }
        if !isLeftParenPresent {
            let error = ASTDiagnosticError("Provide left parenthesis", .error, range)
            errors.append(error)
        }
        if !isRightParenPresent {
            let error = ASTDiagnosticError("Provide right parenthesis", .error, range)
            errors.append(error)
        }
        return errors.count > 0 ? errors : nil
    }
}

class PklMethodCallExpression: ASTNode {
    let uniqueID: UUID = .init()

    var range: ASTRange
    let importDepth: Int
    let document: Document

    var identifier: PklIdentifier?
    var variableCalls: [PklVariable]
    var params: PklMethodParameterList?

    var children: [any ASTNode]? {
        var children: [any ASTNode] = []
        if identifier != nil {
            children.append(identifier!)
        }
        if params != nil {
            children.append(params!)
        }
        return children
    }

    init(identifier: PklIdentifier?, variableCalls: [PklVariable], params: PklMethodParameterList?, range: ASTRange, importDepth: Int, document: Document) {
        self.identifier = identifier
        self.variableCalls = variableCalls
        self.params = params
        self.range = range
        self.importDepth = importDepth
        self.document = document
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        var errors: [ASTDiagnosticError] = []
        if identifier == nil {
            let error = ASTDiagnosticError("Provide method identifier", .error, range)
            errors.append(error)
        }
        if params != nil {
            if let paramErrors = params?.diagnosticErrors() {
                errors.append(contentsOf: paramErrors)
            }
        }
        return errors.count > 0 ? errors : nil
    }
}

class PklNestedMethodCallExpression: ASTNode {
    let uniqueID: UUID = .init()

    var range: ASTRange
    let importDepth: Int
    let document: Document

    var methodCalls: [PklMethodCallExpression]
    var tail: [any ASTNode]?

    var children: [any ASTNode]? {
        var children: [any ASTNode] = methodCalls
        if let tail {
            children.append(contentsOf: tail)
        }
        return children
    }

    init(methodCalls: [PklMethodCallExpression], tail: [any ASTNode]? = nil, range: ASTRange, importDepth: Int, document: Document) {
        self.methodCalls = methodCalls
        self.tail = tail
        self.range = range
        self.importDepth = importDepth
        self.document = document
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        guard methodCalls.count == 0 else {
            let error = ASTDiagnosticError("Zero amount of nested method calls", .error, range)
            return [error]
        }
        var errors: [ASTDiagnosticError] = []
        for child in methodCalls {
            if let childErrors = child.diagnosticErrors() {
                errors.append(contentsOf: childErrors)
            }
        }
        guard let tail else {
            return errors.count > 0 ? errors : nil
        }
        for child in tail {
            if let childErrors = child.diagnosticErrors() {
                errors.append(contentsOf: childErrors)
            }
        }
        return errors.count > 0 ? errors : nil
    }
}

// class PklPropertyCallExpression: ASTNode {
//     let uniqueID: UUID = .init()
//
//     var range: ASTRange
//     let document: Document
//     let importDepth: Int
//
//     var variableFrom: PklVariable?
//     var variableCalls: [PklVariable]
//
//     var children: [ASTNode]? {
//
//     }
//
//     init()
//
// }
