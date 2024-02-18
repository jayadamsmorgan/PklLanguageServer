import Foundation

class IfExpression: ASTNode {
    let condition: ASTNode
    let trueBranch: ASTNode
    let falseBranch: ASTNode
    
    init(condition: ASTNode, trueBranch: ASTNode, falseBranch: ASTNode) {
        self.condition = condition
        self.trueBranch = trueBranch
        self.falseBranch = falseBranch
        super.init()
    }
}

// Usage Example
// If Expression with arithmetic comparison, true branch, and else branch
let exampleIfExpression = IfExpression(
    condition: BinaryExpression(
        left: BinaryExpression(
            left: IntLiteral(value: "2"),
            binaryOperator: .addition,
            right: IntLiteral(value: "2")
        ),
        binaryOperator: .comparison(.equal),
        right: IntLiteral(value: "5")
    ),
    trueBranch: IntLiteral(value: "1984"),
    falseBranch: IntLiteral(value: "42")
)

