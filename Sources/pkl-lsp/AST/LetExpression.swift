import Foundation

class LetExpression: ASTNode {
    let name: String
    let value: ASTNode
    let body: ASTNode
    
    init(name: String, value: ASTNode, body: ASTNode) {
        self.name = name
        self.value = value
        self.body = body
        super.init()
    }
}

// Usage Example
// Defining a let expression with a list and accessing its elements in a subsequent expression
let birdDiets = LetExpression(
    name: "diets",
    value: ListLiteral(elements: [
        StringLiteral(value: "Seeds"),
        StringLiteral(value: "Berries"),
        StringLiteral(value: "Mice")
    ]),
    body: ListLiteral(elements: [
        ListAccess(list: VariableReference(name: "diets"), index: IntLiteral(value: "2")),
        ListAccess(list: VariableReference(name: "diets"), index: IntLiteral(value: "0"))
    ])
)

// Stacked let expressions
let stackedBirdDiets = LetExpression(
    name: "birds",
    value: ListLiteral(elements: [
        StringLiteral(value: "Pigeon"),
        StringLiteral(value: "Barn owl"),
        StringLiteral(value: "Parrot")
    ]),
    body: birdDiets)

