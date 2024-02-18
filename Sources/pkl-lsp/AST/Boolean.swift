import Foundation

class BooleanLiteral: ASTNode {
    let value: Bool
    
    init(value: Bool) {
        self.value = value
        super.init()
    }
}

class LogicalExpression: ASTNode {
    let left: ASTNode
    let logicalOperator: LogicalOperator
    let right: ASTNode?
    
    init(left: ASTNode, logicalOperator: LogicalOperator, right: ASTNode? = nil) {
        self.left = left
        self.logicalOperator = logicalOperator
        self.right = right
        super.init()
    }
}

enum LogicalOperator {
    case conjunction // &&
    case disjunction // ||
    case negation    // !
    case xor         // Exclusive OR
    case implies     // Logical implication
}

// Usage Examples
let exampleRes1 = LogicalExpression(left: BooleanLiteral(value: true), logicalOperator: .conjunction, right: BooleanLiteral(value: false))
let exampleRes2 = LogicalExpression(left: BooleanLiteral(value: true), logicalOperator: .disjunction, right: BooleanLiteral(value: false))
let exampleRes3 = LogicalExpression(left: BooleanLiteral(value: false), logicalOperator: .negation)
let exampleRes4 = LogicalExpression(left: BooleanLiteral(value: true), logicalOperator: .xor, right: BooleanLiteral(value: false))
let exampleRes5 = LogicalExpression(left: BooleanLiteral(value: true), logicalOperator: .implies, right: BooleanLiteral(value: false))

