import Foundation
import LanguageServerProtocol

class PklValue: ASTNode {
    let uniqueID: UUID = .init()

    var range: ASTRange
    let importDepth: Int
    let document: Document

    var value: String?

    var type: PklType?

    var children: [any ASTNode]? = nil

    init(value: String? = nil, type: PklType? = nil, range: ASTRange, importDepth: Int, document: Document) {
        self.value = value
        self.type = type
        self.range = range
        self.importDepth = importDepth
        self.document = document
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        if value != nil {
            return nil
        }
        return [ASTDiagnosticError("Provide value", .error, range)]
    }
}
