import Foundation
import LanguageServerProtocol

public enum PklStandardTypesIdentifiers: String, CaseIterable {
    case Number
    case Int
    case Float
    case String
}

class PklType: ASTNode {
    var identifier: String?

    init(identifier: String? = nil, range: ASTRange, importDepth: Int, document: Document) {
        self.identifier = identifier
        super.init(range: range, importDepth: importDepth, document: document)
    }

    override public func diagnosticErrors() -> [ASTDiagnosticError]? {
        if identifier != nil {
            return nil
        }
        return [ASTDiagnosticError("Provide type identifier", .error, range)]
    }
}

class PklTypeAnnotation: ASTNode {
    var type: PklType?
    var colonIsPresent: Bool = false

    init(type: PklType? = nil, colonIsPresent: Bool = false, range: ASTRange, importDepth: Int, document: Document) {
        self.type = type
        self.colonIsPresent = colonIsPresent
        super.init(range: range, importDepth: importDepth, document: document)
    }

    override public func diagnosticErrors() -> [ASTDiagnosticError]? {
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
