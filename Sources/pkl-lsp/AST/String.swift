import Foundation
import LanguageServerProtocol

struct PklStringLiteral: ASTNode {
    let uniqueID: UUID = .init()

    var range: ASTRange

    var value: String?

    var children: [any ASTNode]? = nil

    init(value: String? = nil, range: ASTRange) {
        self.value = value
        self.range = range
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        if value != nil {
            return nil
        }
        return [ASTDiagnosticError("Provide string value", .error, range)]
    }
}
