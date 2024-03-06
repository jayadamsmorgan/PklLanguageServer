import Foundation
import LanguageServerProtocol

enum PklStringType {
    case constant
    case singleLine
    case multiLine
}

struct PklStringLiteral: ASTNode {
    let uniqueID: UUID = .init()

    var range: ASTRange

    var value: String?

    var type: PklStringType

    var children: [any ASTNode]? = nil

    init(value: String? = nil, type: PklStringType, range: ASTRange) {
        self.value = value
        self.type = type
        self.range = range
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        if value != nil {
            return nil
        }
        return [ASTDiagnosticError("Provide string value", .error, range)]
    }
}
