import Foundation

class VariableDeclaration: ASTNode {
    let name: String
    let type: TypeAnnotation?
    let value: ASTNode?
    
    init(name: String, type: TypeAnnotation? = nil, value: ASTNode? = nil) {
        self.name = name
        self.type = type
        self.value = value
        super.init()
    }
}

class VariableReference: ASTNode {
    let name: String
    
    init(name: String) {
        self.name = name
        super.init()
    }
}

class VariableAssignment: ASTNode {
    let variable: VariableReference
    let newValue: ASTNode
    
    init(variable: VariableReference, newValue: ASTNode) {
        self.variable = variable
        self.newValue = newValue
        super.init()
    }
}

// Usage Examples
// Declaring a variable with an initial value
let birdNameDeclaration = VariableDeclaration(
    name: "birdName",
    value: StringLiteral(value: "\"Parry the Parrot\"")
)

// Declaring a variable with type annotation and initial value
let birdAgeDeclaration = VariableDeclaration(
    name: "birdAge",
    type: TypeAnnotation(type: NumberLiteral(value: "3", type: .int)),
    value: NumberLiteral(value: "3", type: .int)
)

// Referencing a variable
let birdNameReference = VariableReference(name: "birdName")

// Assigning a new value to a variable (if mutable variables are supported)
let birdAgeAssignment = VariableAssignment(
    variable: VariableReference(name: "birdAge"),
    newValue: NumberLiteral(value: "4", type: .int)
)

