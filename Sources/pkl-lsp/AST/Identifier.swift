import Foundation
import LanguageServerProtocol

enum PklIdentifierType {
    case identifier
    case qualifiedIdentifier
}

class PklIdentifier: ASTNode {
    var type: PklIdentifierType

    var value: String

    init(value: String, range: ASTRange, importDepth: Int, document: Document, type: PklIdentifierType = .identifier) {
        self.value = value
        self.type = type
        super.init(range: range, importDepth: importDepth, document: document)
    }
}
