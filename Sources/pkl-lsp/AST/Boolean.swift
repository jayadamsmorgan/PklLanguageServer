import Foundation
import LanguageServerProtocol

class PklBooleanLiteral: ASTNode {
    var value: Bool

    init(value: Bool, range: ASTRange, importDepth: Int, document: Document) {
        self.value = value
        super.init(range: range, importDepth: importDepth, document: document)
    }
}
