import Foundation
import LanguageServerProtocol

class PklClassProperty: ASTNode {
    var identifier: PklIdentifier?
    var typeAnnotation: PklTypeAnnotation?
    var isEqualsPresent: Bool = false
    var value: ASTNode?
    var isHidden: Bool
    var isLocal: Bool

    override var children: [ASTNode]? {
        get {
            var children: [ASTNode] = []
            if let identifier {
                children.append(identifier)
            }
            if let typeAnnotation {
                children.append(typeAnnotation)
            }
            if let value {
                children.append(value)
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
                    } else if value == nil {
                        value = child
                    }
                }
            }
        }
    }

    init(identifier: PklIdentifier? = nil, typeAnnotation: PklTypeAnnotation? = nil, isEqualsPresent: Bool = false, value: ASTNode?,
         isHidden: Bool = false, isLocal: Bool = false, range: ASTRange, importDepth: Int, document: Document)
    {
        self.identifier = identifier
        self.typeAnnotation = typeAnnotation
        self.isEqualsPresent = isEqualsPresent
        self.value = value
        self.isHidden = isHidden
        self.isLocal = isLocal
        super.init(range: range, importDepth: importDepth, document: document)
    }

    override public func diagnosticErrors() -> [ASTDiagnosticError]? {
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

class PklClass: ASTNode {
    var properties: [PklClassProperty]?
    var functions: [PklFunctionDeclaration]?

    var leftBraceIsPresent: Bool = false
    var rightBraceIsPresent: Bool = false

    override var children: [ASTNode]? {
        get {
            var children: [ASTNode] = []
            if let properties {
                children.append(contentsOf: properties)
            }
            if let functions {
                children.append(contentsOf: functions)
            }
            return children
        }
        set {
            if let newValue {
                for child in newValue {
                    if let property = child as? PklClassProperty {
                        if properties == nil {
                            properties = []
                        }
                        properties?.append(property)
                    } else if let function = child as? PklFunctionDeclaration {
                        if functions == nil {
                            functions = []
                        }
                        functions?.append(function)
                    }
                }
            }
        }
    }

    init(properties: [PklClassProperty]? = nil, functions _: [PklFunctionDeclaration]? = nil, leftBraceIsPresent: Bool = false, rightBraceIsPresent: Bool = false,
         range: ASTRange, importDepth: Int, document: Document)
    {
        self.properties = properties
        self.leftBraceIsPresent = leftBraceIsPresent
        self.rightBraceIsPresent = rightBraceIsPresent
        super.init(range: range, importDepth: importDepth, document: document)
    }

    override public func diagnosticErrors() -> [ASTDiagnosticError]? {
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

class PklClassDeclaration: ASTNode {
    var classNode: PklClass?
    var classKeyword: String?
    var classIdentifier: PklIdentifier?

    override var children: [ASTNode]? {
        get {
            var children: [ASTNode] = []
            if let classNode {
                children.append(classNode)
            }
            if let classIdentifier {
                children.append(classIdentifier)
            }
            return children
        }
        set {
            if let newValue {
                for child in newValue {
                    if let classNode = child as? PklClass {
                        self.classNode = classNode
                    } else if let classIdentifier = child as? PklIdentifier {
                        self.classIdentifier = classIdentifier
                    }
                }
            }
        }
    }

    init(classNode: PklClass? = nil, classKeyword: String? = nil, classIdentifier: PklIdentifier? = nil, range: ASTRange, importDepth: Int, document: Document) {
        self.classNode = classNode
        self.classKeyword = classKeyword
        self.classIdentifier = classIdentifier
        super.init(range: range, importDepth: importDepth, document: document)
    }

    override public func diagnosticErrors() -> [ASTDiagnosticError]? {
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
