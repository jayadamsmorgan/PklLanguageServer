import Foundation
import LanguageServerProtocol

struct PklObjectBody: ASTNode {
    let uniqueID: UUID = .init()

    var range: ASTRange
    let importDepth: Int
    let document: Document

    var isLeftBracePresent: Bool = false
    var isRightBracePresent: Bool = false

    var objectProperties: [PklObjectProperty]?
    var objectEntries: [PklObjectEntry]?

    var children: [any ASTNode]? {
        var children: [any ASTNode] = []
        if let objectProperties {
            children.append(contentsOf: objectProperties)
        }
        if let objectEntries {
            children.append(contentsOf: objectEntries)
        }
        return children
    }

    init(objectProperties: [PklObjectProperty]?, objectEntries: [PklObjectEntry]?,
         isLeftBracePresent: Bool = false, isRightBracePresent: Bool = false, range: ASTRange, importDepth: Int, document: Document)
    {
        self.isLeftBracePresent = isLeftBracePresent
        self.isRightBracePresent = isRightBracePresent
        self.objectEntries = objectEntries
        self.objectProperties = objectProperties
        self.range = range
        self.importDepth = importDepth
        self.document = document
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        var errors: [ASTDiagnosticError] = []
        if !isLeftBracePresent {
            let error = ASTDiagnosticError("Provide left brace", .error, range)
            errors.append(error)
        }
        if !isRightBracePresent {
            let error = ASTDiagnosticError("Provide right brace", .error, range)
            errors.append(error)
        }
        if let objectProperties {
            for property in objectProperties {
                if let propertyErrors = property.diagnosticErrors() {
                    errors.append(contentsOf: propertyErrors)
                }
            }
        }
        if let objectEntries {
            for property in objectEntries {
                if let propertyErrors = property.diagnosticErrors() {
                    errors.append(contentsOf: propertyErrors)
                }
            }
        }
        return errors.count > 0 ? errors : nil
    }
}

struct PklObjectProperty: ASTNode {
    let uniqueID: UUID = .init()

    var range: ASTRange
    let importDepth: Int
    let document: Document

    var identifier: PklIdentifier?
    var typeAnnotation: PklTypeAnnotation?
    var value: (any ASTNode)?

    var isEqualsPresent: Bool = false

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

    init(identifier: PklIdentifier? = nil, typeAnnotation: PklTypeAnnotation? = nil, isEqualsPresent: Bool, value: (any ASTNode)?, range: ASTRange, importDepth: Int, document: Document) {
        self.identifier = identifier
        self.typeAnnotation = typeAnnotation
        self.isEqualsPresent = isEqualsPresent
        self.value = value
        self.range = range
        self.importDepth = importDepth
        self.document = document
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        var errors: [ASTDiagnosticError] = []
        if identifier == nil {
            let error = ASTDiagnosticError("Provide property identifier", .error, range)
            errors.append(error)
        }
        if typeAnnotation == nil, value == nil {
            let error = ASTDiagnosticError("Provide property type or value", .error, range)
            errors.append(error)
        }
        if value is PklObjectBody, isEqualsPresent {
            let error = ASTDiagnosticError("Extraneous equals sign before object body", .error, range)
            errors.append(error)
        }
        if value != nil, !(value is PklObjectBody), !isEqualsPresent {
            let error = ASTDiagnosticError("Missing equals sign", .error, range)
            errors.append(error)
        }
        if typeAnnotation != nil {
            if let typeErrors = typeAnnotation?.diagnosticErrors() {
                errors.append(contentsOf: typeErrors)
            }
        }
        if value != nil {
            if let valueErrors = value?.diagnosticErrors() {
                errors.append(contentsOf: valueErrors)
            }
        }
        return errors.count > 0 ? errors : nil
    }
}

struct PklObjectEntry: ASTNode {
    let uniqueID: UUID = .init()

    var range: ASTRange
    let importDepth: Int
    let document: Document

    var strIdentifier: PklStringLiteral?
    var value: (any ASTNode)?

    var isLeftBracketPresent: Bool = false
    var isRightBracketPresent: Bool = false

    var isEqualsPresent: Bool = false

    var children: [any ASTNode]? {
        var children: [any ASTNode] = []
        if let identifier = strIdentifier {
            children.append(identifier)
        }
        if let value {
            children.append(value)
        }
        return children
    }

    init(strIdentifier: PklStringLiteral? = nil, value: (any ASTNode)? = nil, isEqualsPresent: Bool, isLeftBracketPresent: Bool,
         isRightBracketPresent: Bool, range: ASTRange, importDepth: Int, document: Document)
    {
        self.strIdentifier = strIdentifier
        self.value = value
        self.range = range
        self.isLeftBracketPresent = isLeftBracketPresent
        self.isRightBracketPresent = isRightBracketPresent
        self.isEqualsPresent = isEqualsPresent
        self.importDepth = importDepth
        self.document = document
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        var errors: [ASTDiagnosticError] = []
        if strIdentifier == nil {
            let error = ASTDiagnosticError("Provide object entry string identifier", .error, range)
            errors.append(error)
        }
        if value == nil {
            let error = ASTDiagnosticError("Provide object value", .error, range)
            errors.append(error)
        }
        if !isLeftBracketPresent {
            let error = ASTDiagnosticError("Provide left square bracket", .error, range)
            errors.append(error)
        }
        if !isRightBracketPresent {
            let error = ASTDiagnosticError("Provide right square bracket", .error, range)
            errors.append(error)
        }
        if value is PklObjectBody, isEqualsPresent {
            let error = ASTDiagnosticError("Extraneous equals sign", .error, range)
            errors.append(error)
        }
        if value != nil, !(value is PklObjectBody), !isEqualsPresent {
            let error = ASTDiagnosticError("Missing equals sign", .error, range)
            errors.append(error)
        }
        if value != nil {
            if let valueErrors = value?.diagnosticErrors() {
                errors.append(contentsOf: valueErrors)
            }
        }
        return errors.count > 0 ? errors : nil
    }
}
