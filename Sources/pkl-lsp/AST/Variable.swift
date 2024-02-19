import Foundation

class PklVariable : ASTNode {
    var name: String
    var value: ASTNode?

    init(name: String, value: ASTNode? = nil) {
        self.name = name
        self.value = value
        super.init()
    }
}
