import Foundation
import LanguageServerProtocol

struct PklClassProperty : ASTNode {

    let uniqueID: UUID = UUID()

    var positionStart: Position
    var positionEnd: Position

    var identifier: PklIdentifier?
    var typeAnnotation: PklTypeAnnotation?
    var isEqualsPresent: Bool = false
    var value: (any ASTNode)?
    var isHidden: Bool

    init(identifier: PklIdentifier? = nil, typeAnnotation: PklTypeAnnotation? = nil, isEqualsPresent: Bool = false, value: (any ASTNode)?,
        isHidden: Bool = false, positionStart: Position, positionEnd: Position) {
        self.identifier = identifier
        self.typeAnnotation = typeAnnotation
        self.isEqualsPresent = isEqualsPresent
        self.value = value
        self.isHidden = isHidden
        self.positionStart = positionStart
        self.positionEnd = positionEnd
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        var errors: [ASTDiagnosticError] = []
        if typeAnnotation != nil {
            if let typeErrors = typeAnnotation?.diagnosticErrors() {
                errors.append(contentsOf: typeErrors)
            }
        }
        if !isEqualsPresent && value != nil && !(value is PklObjectBody) {
            let error = ASTDiagnosticError("Provide an equals sign", .error, positionStart, positionEnd)
            errors.append(error)
        }
        if value is PklObjectBody && isEqualsPresent {
            let error = ASTDiagnosticError("Extra equals sign", .error, positionStart, positionEnd)
            errors.append(error)
        }
        if isEqualsPresent && value == nil {
            let error = ASTDiagnosticError("Provide a value", .error, positionStart, positionEnd)
            errors.append(error)
        }
        if value != nil {
            if let valueErrors = value?.diagnosticErrors() {
                errors.append(contentsOf: valueErrors)
            }
        }
        if typeAnnotation == nil && value == nil {
            let error = ASTDiagnosticError("Provide property type or value", .error, positionStart, positionEnd)
            errors.append(error)
        }
        if identifier == nil {
            let error = ASTDiagnosticError("Provide property identifier", .error, positionStart, positionEnd)
            errors.append(error)
        }
        return errors.count > 0 ? errors : nil
    }
}

struct PklClass : ASTNode {

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

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        var errors: [ASTDiagnosticError] = []
        if !rightBraceIsPresent {
            let error = ASTDiagnosticError("Missing right brace symbol", .error, positionStart, positionEnd)
            errors.append(error)
        }
        if !leftBraceIsPresent {
            let error = ASTDiagnosticError("Missing left brace symbol", .error, positionStart, positionEnd)
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

struct PklClassDeclaration : ASTNode {

    let uniqueID: UUID = UUID()

    var positionStart: Position
    var positionEnd: Position

    var classNode: PklClass?
    var classKeyword: String?
    var classIdentifier: PklIdentifier?

    init(classNode: PklClass? = nil, classKeyword: String? = nil, classIdentifier: PklIdentifier? = nil, positionStart: Position, positionEnd: Position) {
        self.classNode = classNode
        self.classKeyword = classKeyword
        self.classIdentifier = classIdentifier
        self.positionStart = positionStart
        self.positionEnd = positionEnd
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        var errors: [ASTDiagnosticError] = []
        if classNode != nil {
            if let classErrors = classNode?.diagnosticErrors() {
                errors.append(contentsOf: classErrors)
            }
        }
        if classKeyword != "class" {
            let error = ASTDiagnosticError("Missing class keyword", .error, positionStart, positionEnd)
            errors.append(error)
        }
        if classIdentifier == nil {
            let error = ASTDiagnosticError("Provide class identifier", .error, positionStart, positionEnd)
            errors.append(error)
        }
        return errors.count > 0 ? errors : nil
    }
}

