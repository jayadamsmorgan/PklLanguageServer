import Foundation

class TypeTestExpression: ASTNode {
    let value: ASTNode
    let type: ASTNode // Type can be a simple type like "Int", or a complex type constraint like "String(contains('@'))"
    
    init(value: ASTNode, type: ASTNode) {
        self.value = value
        self.type = type
        super.init()
    }
}

