import Foundation
import LanguageServerProtocol

class PklFunctionParameter: ASTNode {
    var identifier: PklIdentifier?
    var typeAnnotation: PklTypeAnnotation?

    override var children: [ASTNode]? {
        get {
            var children: [ASTNode] = []
            if identifier != nil {
                children.append(identifier!)
            }
            if typeAnnotation != nil {
                children.append(typeAnnotation!)
            }
            return children
        }
        set {
            if let newValue {
                for child in newValue {
                    if let identifier = child as? PklIdentifier {
                        self.identifier = identifier
                    } else if let typeAnnotation = child as? PklTypeAnnotation {
                        self.typeAnnotation = typeAnnotation
                    }
                }
            }
        }
    }

    init(identifier: PklIdentifier?, typeAnnotation: PklTypeAnnotation?, range: ASTRange, importDepth: Int, document: Document) {
        self.identifier = identifier
        self.typeAnnotation = typeAnnotation
        super.init(range: range, importDepth: importDepth, document: document)
    }

    override public func diagnosticErrors() -> [ASTDiagnosticError]? {
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
    var parameters: [PklFunctionParameter]?
    var isLeftParenPresent: Bool = false
    var isRightParenPresent: Bool = false
    var commasAmount: Int = 0

    override var children: [ASTNode]? {
        get {
            var children: [ASTNode] = []
            if parameters != nil {
                children.append(contentsOf: parameters!)
            }
            return children
        }
        set {
            if let newValue {
                for child in newValue {
                    if let parameter = child as? PklFunctionParameter {
                        if parameters == nil {
                            parameters = []
                        }
                        parameters!.append(parameter)
                    }
                }
            }
        }
    }

    init(parameters: [PklFunctionParameter]?, isLeftParenPresent: Bool = false, isRightParenPresent: Bool = false,
         commasAmount: Int = 0, range: ASTRange, importDepth: Int, document: Document)
    {
        self.parameters = parameters
        self.isLeftParenPresent = isLeftParenPresent
        self.isRightParenPresent = isRightParenPresent
        self.commasAmount = commasAmount
        super.init(range: range, importDepth: importDepth, document: document)
    }

    override public func diagnosticErrors() -> [ASTDiagnosticError]? {
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
    var body: PklClassFunctionBody?
    var functionValue: ASTNode?

    override var children: [ASTNode]? {
        get {
            var children: [ASTNode] = []
            if body != nil {
                children.append(body!)
            }
            if functionValue != nil {
                children.append(functionValue!)
            }
            return children
        }
        set {
            if let newValue {
                for child in newValue {
                    if let body = child as? PklClassFunctionBody {
                        self.body = body
                    } else if functionValue == nil {
                        functionValue = child
                    }
                }
            }
        }
    }

    init(body: PklClassFunctionBody?, functionValue: ASTNode?, range: ASTRange, importDepth: Int, document: Document) {
        self.body = body
        self.functionValue = functionValue
        super.init(range: range, importDepth: importDepth, document: document)
    }

    override public func diagnosticErrors() -> [ASTDiagnosticError]? {
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
        if functionValue == nil && body?.isExternal == false {
            let error = ASTDiagnosticError("Provide function value", .error, range)
            errors.append(error)
        }
        return errors.count > 0 ? errors : nil
    }
}

class PklClassFunctionBody: ASTNode {
    var isFunctionKeywordPresent: Bool = false
    var identifier: PklIdentifier?
    var params: PklFunctionParameterList?
    var typeAnnotation: PklTypeAnnotation?

    var isLocal: Bool = false
    var isExternal: Bool = false

    override var children: [ASTNode]? {
        get {
            var children: [ASTNode] = []
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
        set {
            if let newValue {
                for child in newValue {
                    if let identifier = child as? PklIdentifier {
                        self.identifier = identifier
                    } else if let params = child as? PklFunctionParameterList {
                        self.params = params
                    } else if let typeAnnotation = child as? PklTypeAnnotation {
                        self.typeAnnotation = typeAnnotation
                    }
                }
            }
        }
    }

    init(isFunctionKeywordPresent: Bool = false, identifier: PklIdentifier?, params: PklFunctionParameterList?,
         typeAnnotation _: PklTypeAnnotation? = nil, range: ASTRange, importDepth: Int, document: Document)
    {
        self.isFunctionKeywordPresent = isFunctionKeywordPresent
        self.identifier = identifier
        self.params = params
        super.init(range: range, importDepth: importDepth, document: document)
    }

    override public func diagnosticErrors() -> [ASTDiagnosticError]? {
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
    var value: ASTNode?

    override var children: [ASTNode]? {
        get {
            if value != nil {
                return [value!]
            }
            return nil
        }
        set {
            if let newValue {
                for child in newValue {
                    if value == nil {
                        value = child
                    }
                }
            }
        }
    }

    init(value: ASTNode?, range: ASTRange, importDepth: Int, document: Document) {
        self.value = value
        super.init(range: range, importDepth: importDepth, document: document)
    }

    override public func diagnosticErrors() -> [ASTDiagnosticError]? {
        var errors: [ASTDiagnosticError] = []
        if value == nil {
            let error = ASTDiagnosticError("Provide method parameter value", .error, range)
            errors.append(error)
        }
        return errors.count > 0 ? errors : nil
    }
}

class PklMethodParameterList: ASTNode {
    var parameters: [PklMethodParameter]?
    var isLeftParenPresent: Bool = false
    var isRightParenPresent: Bool = false
    var commasAmount: Int = 0

    override var children: [ASTNode]? {
        get {
            var children: [ASTNode] = []
            if parameters != nil {
                children.append(contentsOf: parameters!)
            }
            return children
        }
        set {
            if let newValue {
                for child in newValue {
                    if let parameter = child as? PklMethodParameter {
                        if parameters == nil {
                            parameters = []
                        }
                        parameters!.append(parameter)
                    }
                }
            }
        }
    }

    init(parameters: [PklMethodParameter]?, isLeftParenPresent: Bool = false, isRightParenPresent: Bool = false,
         commasAmount: Int = 0, range: ASTRange, importDepth: Int, document: Document)
    {
        self.parameters = parameters
        self.isLeftParenPresent = isLeftParenPresent
        self.isRightParenPresent = isRightParenPresent
        self.commasAmount = commasAmount
        super.init(range: range, importDepth: importDepth, document: document)
    }

    override public func diagnosticErrors() -> [ASTDiagnosticError]? {
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
    var identifier: PklIdentifier?
    var variableCalls: [PklVariable]
    var params: PklMethodParameterList?

    override var children: [ASTNode]? {
        get {
            var children: [ASTNode] = []
            if identifier != nil {
                children.append(identifier!)
            }
            if params != nil {
                children.append(params!)
            }
            return children
        }
        set {
            if let newValue {
                for child in newValue {
                    if let identifier = child as? PklIdentifier {
                        self.identifier = identifier
                    } else if let params = child as? PklMethodParameterList {
                        self.params = params
                    }
                }
            }
        }
    }

    init(identifier: PklIdentifier?, variableCalls: [PklVariable], params: PklMethodParameterList?, range: ASTRange, importDepth: Int, document: Document) {
        self.identifier = identifier
        self.variableCalls = variableCalls
        self.params = params
        super.init(range: range, importDepth: importDepth, document: document)
    }

    override public func diagnosticErrors() -> [ASTDiagnosticError]? {
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
    var methodCalls: [PklMethodCallExpression]
    var tail: [ASTNode]?

    override var children: [ASTNode]? {
        get {
            var children: [ASTNode] = methodCalls
            if let tail {
                children.append(contentsOf: tail)
            }
            return children
        }
        set {
            if let newValue {
                for child in newValue {
                    if let methodCall = child as? PklMethodCallExpression {
                        methodCalls.append(methodCall)
                    } else if tail == nil {
                        tail = []
                    }
                    tail!.append(child)
                }
            }
        }
    }

    init(methodCalls: [PklMethodCallExpression], tail: [ASTNode]? = nil, range: ASTRange, importDepth: Int, document: Document) {
        self.methodCalls = methodCalls
        self.tail = tail
        super.init(range: range, importDepth: importDepth, document: document)
    }

    override public func diagnosticErrors() -> [ASTDiagnosticError]? {
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
//     var importDepth: Int
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
