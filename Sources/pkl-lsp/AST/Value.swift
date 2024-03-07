import Foundation
import LanguageServerProtocol

struct PklValue: ASTNode {
    let uniqueID: UUID = .init()

    var range: ASTRange
    let importDepth: Int

    var value: String?

    var type: PklType?

    var children: [any ASTNode]? = nil

    init(value: String? = nil, type: PklType? = nil, range: ASTRange, importDepth: Int) {
        self.value = value
        self.type = type
        self.range = range
        self.importDepth = importDepth
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        if value != nil {
            return nil
        }
        return [ASTDiagnosticError("Provide value", .error, range)]
    }
}
