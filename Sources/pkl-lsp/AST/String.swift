import Foundation

class PklStringLiteral : ASTNode {
    var value: String?

    init(value: String? = nil) {
        self.value = value
        super.init()
    }
}

