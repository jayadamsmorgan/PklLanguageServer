import Foundation
import LanguageServerProtocol

public enum PklStandardTypesIdentifiers: String, CaseIterable {
    case Number
    case Int
    case Float
    case String
}

class PklType: ASTNode {
    let uniqueID: UUID = .init()

    var range: ASTRange
    let importDepth: Int
    let document: Document

    var identifier: String?

    var children: [any ASTNode]? = nil

    init(identifier: String? = nil, range: ASTRange, importDepth: Int, document: Document) {
        self.identifier = identifier
        self.range = range
        self.importDepth = importDepth
        self.document = document
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        if identifier != nil {
            return nil
        }
        return [ASTDiagnosticError("Provide type identifier", .error, range)]
    }
}

class PklTypeAnnotation: ASTNode {
    let uniqueID: UUID = .init()

    var range: ASTRange
    let importDepth: Int
    let document: Document

    var type: PklType?
    var colonIsPresent: Bool = false

    var children: [any ASTNode]? = nil

    init(type: PklType? = nil, colonIsPresent: Bool = false, range: ASTRange, importDepth: Int, document: Document) {
        self.type = type
        self.colonIsPresent = colonIsPresent
        self.range = range
        self.importDepth = importDepth
        self.document = document
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        var errors: [ASTDiagnosticError] = []
        if !colonIsPresent {
            let error = ASTDiagnosticError("Missing colon before type identifier", .error, range)
            errors.append(error)
        }
        if type != nil {
            if let typeErrors = type?.diagnosticErrors() {
                errors.append(contentsOf: typeErrors)
            }
        }
        if type == nil {
            let error = ASTDiagnosticError("Provide type identifier", .error, range)
            errors.append(error)
        }
        return errors.count > 0 ? errors : nil
    }
}
