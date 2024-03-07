import Foundation
import LanguageServerProtocol

struct PklIdentifier: ASTNode {
    let uniqueID: UUID = .init()

    var range: ASTRange
    let importDepth: Int

    var value: String

    var children: [any ASTNode]? = nil

    init(value: String, range: ASTRange, importDepth: Int) {
        self.value = value
        self.range = range
        self.importDepth = importDepth
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        nil
    }
}
