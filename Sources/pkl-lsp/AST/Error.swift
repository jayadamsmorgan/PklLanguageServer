import Foundation

class ThrowExpression: ASTNode {
    let message: ASTNode
    
    init(message: ASTNode) {
        self.message = message
        super.init()
    }
}

// Usage Example
// Raising an error with a throw expression
let exampleThrowError = ThrowExpression(message: StringLiteral(value: "You won't be able to recover from this one!"))

