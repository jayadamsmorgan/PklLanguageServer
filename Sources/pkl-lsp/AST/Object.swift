import Foundation
import LanguageServerProtocol

struct PklObjectBody: ASTNode {
    let uniqueID: UUID = .init()

    var positionStart: Position
    var positionEnd: Position

    var isLeftBracePresent: Bool = false
    var isRightBracePresent: Bool = false

    var properties: [PklObjectProperty]?

    var children: [any ASTNode]? {
        properties
    }

    init(properties: [PklObjectProperty]?, isLeftBracePresent: Bool = false, isRightBracePresent: Bool = false, positionStart: Position, positionEnd: Position) {
        self.isLeftBracePresent = isLeftBracePresent
        self.isRightBracePresent = isRightBracePresent
        self.properties = properties
        self.positionStart = positionStart
        self.positionEnd = positionEnd
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        var errors: [ASTDiagnosticError] = []
        if !isLeftBracePresent {
            let error = ASTDiagnosticError("Provide left brace", .error, positionStart, positionEnd)
            errors.append(error)
        }
        if !isRightBracePresent {
            let error = ASTDiagnosticError("Provide right brace", .error, positionStart, positionEnd)
            errors.append(error)
        }
        if let properties {
            for property in properties {
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

    var positionStart: Position
    var positionEnd: Position

    var identifier: PklIdentifier?
    var typeAnnotation: PklTypeAnnotation?
    var value: (any ASTNode)?

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

    init(identifier: PklIdentifier? = nil, typeAnnotation: PklTypeAnnotation? = nil, value: (any ASTNode)?, positionStart: Position, positionEnd: Position) {
        self.identifier = identifier
        self.typeAnnotation = typeAnnotation
        self.value = value
        self.positionStart = positionStart
        self.positionEnd = positionEnd
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        var errors: [ASTDiagnosticError] = []
        if identifier == nil {
            let error = ASTDiagnosticError("Provide property identifier", .error, positionStart, positionEnd)
            errors.append(error)
        }
        if typeAnnotation == nil, value == nil {
            let error = ASTDiagnosticError("Provide property type or value", .error, positionStart, positionEnd)
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
        return nil
    }
}
