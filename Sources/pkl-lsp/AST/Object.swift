import Foundation
import LanguageServerProtocol

class PklObjectBody: ASTNode {
    var isLeftBracePresent: Bool = false
    var isRightBracePresent: Bool = false

    var objectProperties: [PklObjectProperty]?
    var objectEntries: [PklObjectEntry]?

    override var children: [ASTNode]? {
        get {
            var children: [ASTNode] = []
            if let objectProperties {
                children.append(contentsOf: objectProperties)
            }
            if let objectEntries {
                children.append(contentsOf: objectEntries)
            }
            return children
        }
        set {
            if let newValue {
                for child in newValue {
                    if let objectProperty = child as? PklObjectProperty {
                        if objectProperties == nil {
                            objectProperties = []
                        }
                        objectProperties?.append(objectProperty)
                    } else if let objectEntry = child as? PklObjectEntry {
                        if objectEntries == nil {
                            objectEntries = []
                        }
                        objectEntries?.append(objectEntry)
                    }
                }
            }
        }
    }

    init(objectProperties: [PklObjectProperty]?, objectEntries: [PklObjectEntry]?,
         isLeftBracePresent: Bool = false, isRightBracePresent: Bool = false, range: ASTRange, importDepth: Int, document: Document)
    {
        self.isLeftBracePresent = isLeftBracePresent
        self.isRightBracePresent = isRightBracePresent
        self.objectEntries = objectEntries
        self.objectProperties = objectProperties
        super.init(range: range, importDepth: importDepth, document: document)
    }

    override public func diagnosticErrors() -> [ASTDiagnosticError]? {
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

class PklObjectProperty: ASTNode {
    var identifier: PklIdentifier?
    var typeAnnotation: PklTypeAnnotation?
    var value: ASTNode?

    var isEqualsPresent: Bool = false

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

    init(identifier: PklIdentifier? = nil, typeAnnotation: PklTypeAnnotation? = nil, isEqualsPresent: Bool,
         value: ASTNode?, range: ASTRange, importDepth: Int, document: Document)
    {
        self.identifier = identifier
        self.typeAnnotation = typeAnnotation
        self.isEqualsPresent = isEqualsPresent
        self.value = value
        super.init(range: range, importDepth: importDepth, document: document)
    }

    override public func diagnosticErrors() -> [ASTDiagnosticError]? {
        var errors: [ASTDiagnosticError] = []
        if identifier == nil {
            let error = ASTDiagnosticError("Provide property identifier", .error, range)
            errors.append(error)
        }
        // if typeAnnotation == nil, value == nil {
        //     let error = ASTDiagnosticError("Provide property type or value", .error, range)
        //     errors.append(error)
        // }
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

class PklObjectEntry: ASTNode {
    var strIdentifier: PklStringLiteral?
    var value: ASTNode?

    var isLeftBracketPresent: Bool = false
    var isRightBracketPresent: Bool = false

    var isEqualsPresent: Bool = false

    override var children: [ASTNode]? {
        get {
            var children: [ASTNode] = []
            if let strIdentifier {
                children.append(strIdentifier)
            }
            if let value {
                children.append(value)
            }
            return children
        }
        set {
            if let newValue {
                for child in newValue {
                    if let strIdentifier = child as? PklStringLiteral {
                        self.strIdentifier = strIdentifier
                    } else if value == nil {
                        value = child
                    }
                }
            }
        }
    }

    init(strIdentifier: PklStringLiteral? = nil, value: ASTNode? = nil, isEqualsPresent: Bool, isLeftBracketPresent: Bool,
         isRightBracketPresent: Bool, range: ASTRange, importDepth: Int, document: Document)
    {
        self.strIdentifier = strIdentifier
        self.value = value
        self.isLeftBracketPresent = isLeftBracketPresent
        self.isRightBracketPresent = isRightBracketPresent
        self.isEqualsPresent = isEqualsPresent
        super.init(range: range, importDepth: importDepth, document: document)
    }

    override public func diagnosticErrors() -> [ASTDiagnosticError]? {
        var errors: [ASTDiagnosticError] = []
        if strIdentifier == nil {
            let error = ASTDiagnosticError("Provide object entry string identifier", .error, range)
            errors.append(error)
        }
        // if value == nil {
        //     let error = ASTDiagnosticError("Provide object value", .error, range)
        //     errors.append(error)
        // }
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
