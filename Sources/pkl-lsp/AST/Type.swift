import Foundation
import LanguageServerProtocol


public enum PklStandardTypesIdentifiers : String, CaseIterable {
    case Number
    case Int
    case Float
    case String
}

struct PklType : ASTNode {

    let uniqueID: UUID = UUID()

    var positionStart: Position
    var positionEnd: Position

    var identifier: String?

    var children: [any ASTNode]? = nil

    init(identifier: String? = nil, positionStart: Position, positionEnd: Position) {
        self.identifier = identifier
        self.positionStart = positionStart
        self.positionEnd = positionEnd
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        if identifier != nil {
            return nil
        }
        return [ASTDiagnosticError("Provide type identifier", .error, positionStart, positionEnd)]
    }
}

struct PklTypeAnnotation : ASTNode {

    let uniqueID: UUID = UUID()

    var positionStart: Position
    var positionEnd: Position
    
    var type: PklType?
    var colonIsPresent: Bool = false

    var children: [any ASTNode]? = nil

    init(type: PklType? = nil, colonIsPresent: Bool = false, positionStart: Position, positionEnd: Position) {
        self.type = type
        self.colonIsPresent = colonIsPresent
        self.positionStart = positionStart
        self.positionEnd = positionEnd
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        var errors: [ASTDiagnosticError] = []
        if !colonIsPresent {
            let error = ASTDiagnosticError("Missing colon before type identifier", .error, positionStart, positionEnd)
            errors.append(error)
        }
        if type != nil {
            if let typeErrors = type?.diagnosticErrors() {
                errors.append(contentsOf: typeErrors)
            }
        }
        if type == nil {
            let error = ASTDiagnosticError("Provide type identifier", .error, positionStart, positionEnd)
            errors.append(error)
        }
        return errors.count > 0 ? errors : nil
    }

}

