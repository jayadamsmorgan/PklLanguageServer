import Foundation

class SetLiteral: ASTNode {
    var elements: [ASTNode]
    
    init(elements: [ASTNode]) {
        self.elements = elements
    }
}

class SetOperation: ASTNode {
    enum OperationType {
        case union, intersect, contains, drop, take, map
    }
    
    let operation: OperationType
    let set: ASTNode
    let argument: ASTNode?
    
    init(operation: OperationType, set: ASTNode, argument: ASTNode? = nil) {
        self.operation = operation
        self.set = set
        self.argument = argument
    }
}

// Usage Examples
// Constructing sets
let emptySet = SetLiteral(elements: [])
let numberSet = SetLiteral(elements: [IntLiteral(value: "1"), IntLiteral(value: "2"), IntLiteral(value: "3"), IntLiteral(value: "1")])
let heterogenousSet = SetLiteral(elements: [IntLiteral(value: "1"), StringLiteral(value: "\"x\""), IntLiteral(value: "5"), ListLiteral(elements: [IntLiteral(value: "1"), IntLiteral(value: "2"), IntLiteral(value: "3")])])

// Computing the union of sets
let unionSet = SetOperation(operation: .union, set: numberSet, argument: SetLiteral(elements: [IntLiteral(value: "2"), IntLiteral(value: "3"), IntLiteral(value: "5"), IntLiteral(value: "3")]))

// Set operations
let exampleSetContainsThree = SetOperation(operation: .contains, set: numberSet, argument: IntLiteral(value: "3"))
let exampleSetDroppedFirst = SetOperation(operation: .drop, set: numberSet, argument: IntLiteral(value: "1"))
let exampleSetTakenTwo = SetOperation(operation: .take, set: numberSet, argument: IntLiteral(value: "2"))
let exampleSetTripledValues = SetOperation(operation: .map, set: numberSet, argument: LambdaExpression(parameters: ["n"], body: BinaryExpression(left: VariableReference(name: "n"), binaryOperator: .multiplication, right: IntLiteral(value: "3"))))
let exampleSetIntersection = SetOperation(operation: .intersect, set: numberSet, argument: SetLiteral(elements: [IntLiteral(value: "3"), IntLiteral(value: "9"), IntLiteral(value: "2")]))

