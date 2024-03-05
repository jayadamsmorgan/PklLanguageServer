import Foundation
import LanguageServerProtocol

struct PklFunctionParameter: ASTNode {
    var uniqueID: UUID = .init()

    var range: ASTRange

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

    init(identifier: PklIdentifier?, typeAnnotation: PklTypeAnnotation?, range: ASTRange) {
        self.identifier = identifier
        self.typeAnnotation = typeAnnotation
        self.range = range
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

struct PklFunctionParameterList: ASTNode {
    var uniqueID: UUID = .init()

    var range: ASTRange

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
         commasAmount: Int = 0, range: ASTRange)
    {
        self.parameters = parameters
        self.isLeftParenPresent = isLeftParenPresent
        self.isRightParenPresent = isRightParenPresent
        self.commasAmount = commasAmount
        self.range = range
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

struct PklFunctionDeclaration: ASTNode {
    let uniqueID: UUID = .init()

    var range: ASTRange

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

    init(body: PklClassFunctionBody?, functionValue: (any ASTNode)?, range: ASTRange) {
        self.body = body
        self.functionValue = functionValue
        self.range = range
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

struct PklClassFunctionBody: ASTNode {
    let uniqueID: UUID = .init()

    var range: ASTRange

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
         typeAnnotation _: PklTypeAnnotation? = nil, range: ASTRange)
    {
        self.isFunctionKeywordPresent = isFunctionKeywordPresent
        self.identifier = identifier
        self.params = params
        self.range = range
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
