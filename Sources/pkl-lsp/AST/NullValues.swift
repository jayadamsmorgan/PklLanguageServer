import Foundation

class NonNullAssertion: ASTNode {
    let operand: ASTNode
    
    init(operand: ASTNode) {
        self.operand = operand
        super.init()
    }
}

class NullCoalescing: ASTNode {
    let lhs: ASTNode
    let rhs: ASTNode
    
    init(lhs: ASTNode, rhs: ASTNode) {
        self.lhs = lhs
        self.rhs = rhs
        super.init()
    }
}

class NullPropagation: ASTNode {
    let operand: ASTNode
    let member: String
    
    init(operand: ASTNode, member: String) {
        self.operand = operand
        self.member = member
        super.init()
    }
}

class IfNonNull: ASTNode {
    let operand: ASTNode
    let closure: FunctionLiteral
    
    init(operand: ASTNode, closure: FunctionLiteral) {
        self.operand = operand
        self.closure = closure
        super.init()
    }
}

class NonNullTypeAlias: ASTNode {
    let type: String
    
    init(type: String) {
        self.type = type
        super.init()
    }
}

class NullValueConstruction: ASTNode {
    let defaultValue: ASTNode?
    
    init(defaultValue: ASTNode? = nil) {
        self.defaultValue = defaultValue
        super.init()
    }
}

class NullValueAmending: ASTNode {
    let nullValue: ASTNode
    let amendments: [ASTNode]
    
    init(nullValue: ASTNode, amendments: [ASTNode]) {
        self.nullValue = nullValue
        self.amendments = amendments
        super.init()
    }
}

// Usage Examples
// Constructing a null value with a default
let test = ObjectLiteral(properties: ["test": ASTNode()])
let nullWithDefault = NullValueConstruction(
    defaultValue: ObjectLiteral(
        properties: [
            "animalAmount" : IntLiteral(value: "3")
        ]
    )
)

// Amending a null value to add properties
let petAmendment = NullValueAmending(
    nullValue: nullWithDefault,
    amendments: [
        VariableDeclaration(name: "name", value: StringLiteral(value: "\"Parry the Parrot\""))
    ]
)

// Amending a predefined null value as if it were a dynamic object
let predefinedNullAmendment = NullValueAmending(
    nullValue: NullValueConstruction(), // Represents the predefined `null` value
    amendments: [
        VariableDeclaration(name: "name", value: StringLiteral(value: "\"Parry the Parrot\""))
    ]
)

// Amending a nullable property to "switch it on" without adding properties
let switchOnPet = NullValueAmending(
    nullValue: VariableReference(name: "pet"), // Assumes `pet` is previously defined as `Null(new Dynamic {})` or similar
    amendments: [] // No amendments, simply "switching on" the null value
)

// Null Literal
let nullValue = NullValueConstruction()

// Non-Null Assertion
let nonNullName = NonNullAssertion(operand: VariableReference(name: "name"))

// Null Coalescing
let nameOrParrot = NullCoalescing(lhs: VariableReference(name: "name"), rhs: StringLiteral(value: "Parrot"))

// Null Propagation
let nameLength = NullPropagation(operand: VariableReference(name: "name"), member: "length")

// ifNonNull Method Invocation
let nameWithTitle = IfNonNull(
    operand: VariableReference(name: "name"),
    closure: FunctionLiteral(parameters: ["it"], returnType: nil, body: StringConcatenation(left: StringLiteral(value: "Dr. "), right: VariableReference(name: "it")))
)

// NonNull Type Alias
let nonNullVariable = NonNullTypeAlias(type: "String")

