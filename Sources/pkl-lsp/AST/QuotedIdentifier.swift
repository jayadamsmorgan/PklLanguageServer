import Foundation

class Identifier: ASTNode {
    let name: String
    let isQuoted: Bool
    
    init(name: String, isQuoted: Bool = false) {
        self.name = name
        self.isQuoted = isQuoted
        super.init()
    }
}
