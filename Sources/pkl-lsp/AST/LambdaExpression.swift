import Foundation

class LambdaExpression: ASTNode {
    var parameters: [String]
    var body: ASTNode
    var returnType: ASTNode?
    
    init(parameters: [String], body: ASTNode, returnType: ASTNode? = nil) {
        self.parameters = parameters
        self.body = body
        self.returnType = returnType
        super.init()
    }
}

// Usage Example
// A simple lambda expression that triples a number
let tripleLambda = LambdaExpression(
    parameters: ["n"],
    body: BinaryExpression(
        left: VariableReference(name: "n"),
        binaryOperator: .multiplication,
        right: NumberLiteral(value: "3", type: .int)
    )
)

// A lambda expression with type annotations (if supported)
let typedTripleLambda = LambdaExpression(
    parameters: ["n"],
    body: BinaryExpression(
        left: VariableReference(name: "n"),
        binaryOperator: .multiplication,
        right: NumberLiteral(value: "3", type: .int)
    ),
    returnType: IntLiteral(value: "3")
)

// A lambda expression used in a higher-order function call
let listMapLambda = FunctionApplication(
    function: VariableReference(name: "List.map"),
    arguments: [
        ListLiteral(elements: [IntLiteral(value: "1"), IntLiteral(value: "2"), IntLiteral(value: "3")]),
        LambdaExpression(
            parameters: ["n"],
            body: BinaryExpression(
                left: VariableReference(name: "n"),
                binaryOperator: .multiplication,
                right: IntLiteral(value: "2")
            )
        )
    ]
)

