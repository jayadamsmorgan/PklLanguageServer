import Foundation
import LanguageServerProtocol

class PklUnidentified: ASTNode {
    var text: String

    init(text: String, range: ASTRange, importDepth: Int, document: Document) {
        self.text = text
        super.init(range: range, importDepth: importDepth, document: document)
    }

    override func diagnosticErrors() -> [ASTDiagnosticError]? {
        return [ASTDiagnosticError("Unexpected identifier", .error, range)]
    }
}
