import Foundation

class PklValue: ASTNode {
    var value: String?

    var type: PklType?

    init(value: String? = nil, type: PklType? = nil, range: ASTRange, importDepth: Int, document: Document) {
        self.value = value
        self.type = type
        super.init(range: range, importDepth: importDepth, document: document)
    }

    override public func diagnosticErrors() -> [ASTDiagnosticError]? {
        if value != nil {
            return nil
        }
        return [ASTDiagnosticError("Provide value", .error, range)]
    }
}
