import Foundation
import LanguageServerProtocol

struct PklIdentifier: ASTNode {
    let uniqueID: UUID = .init()

    var range: ASTRange

    var value: String

    var children: [any ASTNode]? = nil

    init(value: String, range: ASTRange) {
        self.value = value
        self.range = range
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        nil
    }
}
