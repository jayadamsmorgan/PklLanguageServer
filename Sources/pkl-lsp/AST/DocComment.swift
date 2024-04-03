import Foundation
import LanguageServerProtocol

public class PklDocComment: ASTNode {
    var text: String

    init(text: String, range: ASTRange, importDepth: Int, document: Document) {
        self.text = text
        super.init(range: range, importDepth: importDepth, document: document)
    }
}
