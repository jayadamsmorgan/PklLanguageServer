import Foundation

class AnonymousFunctionLiteral: ASTNode {
    var parameters: [String]
    var returnType: ASTNode?
    var body: ASTNode
    
    init(parameters: [String], returnType: ASTNode? = nil, body: ASTNode) {
        self.parameters = parameters
        self.returnType = returnType
        self.body = body
        super.init()
    }
}

class FunctionApplication: ASTNode {
    var function: ASTNode
    var arguments: [ASTNode]
    
    init(function: ASTNode, arguments: [ASTNode]) {
        self.function = function
        self.arguments = arguments
        super.init()
    }
}

class MixinDeclaration: ASTNode {
    var mixinType: ASTNode?
    var properties: [ASTNode]
    
    init(mixinType: ASTNode? = nil, properties: [ASTNode]) {
        self.mixinType = mixinType
        self.properties = properties
        super.init()
    }
}

class FunctionAmending: ASTNode {
    var function: ASTNode
    var amendments: [ASTNode]
    
    init(function: ASTNode, amendments: [ASTNode]) {
        self.function = function
        self.amendments = amendments
        super.init()
    }
}

// Usage Examples
// Anonymous function literal
let exampleTripleFunction = AnonymousFunctionLiteral(
    parameters: ["n"],
    body: BinaryExpression(left: VariableReference(name: "n"), binaryOperator: .multiplication, right: IntLiteral(value: "3"))
)

// Applying an anonymous function
let exampleAppliedTriple = FunctionApplication(
    function: exampleTripleFunction,
    arguments: [IntLiteral(value: "4")]
)

// Mixin declaration
let exampleWithDietMixin = MixinDeclaration(
    properties: [VariableDeclaration(name: "diet", value: StringLiteral(value: "\"Seeds\""))]
)

// Function amending
let exampleBirdsMappingAmending = FunctionAmending(
    function: VariableReference(name: "defaultBirdsMapping"),
    amendments: [VariableDeclaration(name: "diet", value: StringLiteral(value: "\"Seeds\""))]
)

