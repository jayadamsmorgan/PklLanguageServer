import Foundation
import LanguageServerProtocol

public enum PklStandardTypesIdentifiers: String, CaseIterable {
    case Number
    case Int
    case Float
    case String
}

struct PklType: ASTNode {
    let uniqueID: UUID = .init()

    var range: ASTRange
    let importDepth: Int

    var identifier: String?

    var children: [any ASTNode]? = nil

    init(identifier: String? = nil, range: ASTRange, importDepth: Int) {
        self.identifier = identifier
        self.range = range
        self.importDepth = importDepth
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        if identifier != nil {
            return nil
        }
        return [ASTDiagnosticError("Provide type identifier", .error, range)]
    }
}

struct PklTypeAnnotation: ASTNode {
    let uniqueID: UUID = .init()

    var range: ASTRange
    let importDepth: Int

    var type: PklType?
    var colonIsPresent: Bool = false

    var children: [any ASTNode]? = nil

    init(type: PklType? = nil, colonIsPresent: Bool = false, range: ASTRange, importDepth: Int) {
        self.type = type
        self.colonIsPresent = colonIsPresent
        self.range = range
        self.importDepth = importDepth
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
