import Foundation
import LanguageServerProtocol

struct PklValue: ASTNode {
    let uniqueID: UUID = .init()

    var range: ASTRange

    var value: String?

    var type: PklType?

    var children: [any ASTNode]? = nil

    init(value: String? = nil, type: PklType? = nil, range: ASTRange) {
        self.value = value
        self.type = type
        self.range = range
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        if value != nil {
            return nil
        }
        return [ASTDiagnosticError("Provide value", .error, range)]
    }
}
