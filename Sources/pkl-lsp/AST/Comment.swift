import Foundation

class Comment: ASTNode {
    let text: String

    init(text: String) {
        self.text = text
    }
}

class BlockComment {
    let text: String

    init(text: String) {
        self.text = text
    }
}

class DocComment: ASTNode {
    let text: String

    init(text: String) {
        self.text = text
        super.init()
    }
}

