import Foundation
import LanguageServerProtocol

struct PklClassProperty: ASTNode {
    let uniqueID: UUID = .init()

    var range: ASTRange
    let importDepth: Int

    var identifier: PklIdentifier?
    var typeAnnotation: PklTypeAnnotation?
    var isEqualsPresent: Bool = false
    var value: (any ASTNode)?
    var isHidden: Bool

    var children: [any ASTNode]? {
        var children: [any ASTNode] = []
        if identifier != nil {
            children.append(identifier!)
        }
        if typeAnnotation != nil {
            children.append(typeAnnotation!)
        }
        if value != nil {
            children.append(value!)
        }
        return children
    }

    init(identifier: PklIdentifier? = nil, typeAnnotation: PklTypeAnnotation? = nil, isEqualsPresent: Bool = false, value: (any ASTNode)?,
         isHidden: Bool = false, range: ASTRange, importDepth: Int)
    {
        self.identifier = identifier
        self.typeAnnotation = typeAnnotation
        self.isEqualsPresent = isEqualsPresent
        self.value = value
        self.isHidden = isHidden
        self.range = range
        self.importDepth = importDepth
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        var errors: [ASTDiagnosticError] = []
        if typeAnnotation != nil {
            if let typeErrors = typeAnnotation?.diagnosticErrors() {
                errors.append(contentsOf: typeErrors)
            }
        }
        if !isEqualsPresent, value != nil, !(value is PklObjectBody) {
            let error = ASTDiagnosticError("Provide an equals sign", .error, range)
            errors.append(error)
        }
        if value is PklObjectBody, isEqualsPresent {
            let error = ASTDiagnosticError("Extra equals sign", .error, range)
            errors.append(error)
        }
        if isEqualsPresent, value == nil {
            let error = ASTDiagnosticError("Provide a value", .error, range)
            errors.append(error)
        }
        if value != nil {
            if let valueErrors = value?.diagnosticErrors() {
                errors.append(contentsOf: valueErrors)
            }
        }
        if typeAnnotation == nil, value == nil {
            let error = ASTDiagnosticError("Provide property type or value", .error, range)
            errors.append(error)
        }
        if identifier == nil {
            let error = ASTDiagnosticError("Provide property identifier", .error, range)
            errors.append(error)
        }
        return errors.count > 0 ? errors : nil
    }
}

struct PklClass: ASTNode {
    let uniqueID: UUID = .init()

    var range: ASTRange
    let importDepth: Int

    var properties: [PklClassProperty]?
    var functions: [PklFunctionDeclaration]?

    var leftBraceIsPresent: Bool = false
    var rightBraceIsPresent: Bool = false

    var children: [any ASTNode]? {
        var children: [any ASTNode] = []
        if properties != nil {
            children.append(contentsOf: properties!)
        }
        if functions != nil {
            children.append(contentsOf: functions!)
        }
        return children
    }

    init(properties: [PklClassProperty]? = nil, functions _: [PklFunctionDeclaration]? = nil, leftBraceIsPresent: Bool = false, rightBraceIsPresent: Bool = false,
         range: ASTRange, importDepth: Int)
    {
        self.properties = properties
        self.leftBraceIsPresent = leftBraceIsPresent
        self.rightBraceIsPresent = rightBraceIsPresent
        self.range = range
        self.importDepth = importDepth
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        var errors: [ASTDiagnosticError] = []
        if !rightBraceIsPresent {
            let error = ASTDiagnosticError("Missing right brace symbol", .error, range)
            errors.append(error)
        }
        if !leftBraceIsPresent {
            let error = ASTDiagnosticError("Missing left brace symbol", .error, range)
            errors.append(error)
        }
        if properties != nil {
            for property in properties! {
                if let error = property.diagnosticErrors() {
                    errors.append(contentsOf: error)
                }
            }
        }
        if functions != nil {
            for function in functions! {
                if let error = function.diagnosticErrors() {
                    errors.append(contentsOf: error)
                }
            }
        }
        return errors.count > 0 ? errors : nil
    }
}

struct PklClassDeclaration: ASTNode {
    let uniqueID: UUID = .init()

    var range: ASTRange
    let importDepth: Int

    var classNode: PklClass?
    var classKeyword: String?
    var classIdentifier: PklIdentifier?

    var children: [any ASTNode]? {
        var children: [any ASTNode] = []
        if classNode != nil {
            children.append(classNode!)
        }
        if classIdentifier != nil {
            children.append(classIdentifier!)
        }
        return children
    }

    init(classNode: PklClass? = nil, classKeyword: String? = nil, classIdentifier: PklIdentifier? = nil, range: ASTRange, importDepth: Int) {
        self.classNode = classNode
        self.classKeyword = classKeyword
        self.classIdentifier = classIdentifier
        self.range = range
        self.importDepth = 0
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        var errors: [ASTDiagnosticError] = []
        if classNode != nil {
            if let classErrors = classNode?.diagnosticErrors() {
                errors.append(contentsOf: classErrors)
            }
        }
        if classKeyword != "class" {
            let error = ASTDiagnosticError("Missing class keyword", .error, range)
            errors.append(error)
        }
        if classIdentifier == nil {
            let error = ASTDiagnosticError("Provide class identifier", .error, range)
            errors.append(error)
        }
        return errors.count > 0 ? errors : nil
    }
}
