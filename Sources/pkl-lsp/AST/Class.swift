import Foundation

class ClassDeclaration: ASTNode {
    let name: String
    let superClass: ClassDeclaration?
    var properties: [ClassProperty]
    
    init(name: String, superClass: ClassDeclaration? = nil, properties: [ClassProperty]) {
        self.name = name
        self.superClass = superClass
        self.properties = properties
        super.init()
    }
}

class ClassProperty: ASTNode {
    let name: String
    let type: ASTNode
    let isHidden: Bool
    
    init(name: String, type: ASTNode, isHidden: Bool = false) {
        self.name = name
        self.type = type
        self.isHidden = isHidden
        super.init()
    }
}

class ClassInstanceCreation: ASTNode {
    let className: String
    var propertyValues: [String: ASTNode]
    
    init(className: String, propertyValues: [String: ASTNode]) {
        self.className = className
        self.propertyValues = propertyValues
        super.init()
    }
}

class MethodDeclaration: ASTNode {
    let name: String
    let returnType: String
    let parameters: [MethodParameter]
    let body: ASTNode // Assuming a single expression for simplicity; extend as needed
    
    init(name: String, returnType: String, parameters: [MethodParameter], body: ASTNode) {
        self.name = name
        self.returnType = returnType
        self.parameters = parameters
        self.body = body
        super.init()
    }
}

class MethodParameter: ASTNode {
    let name: String
    let type: String
    
    init(name: String, type: String) {
        self.name = name
        self.type = type
        super.init()
    }
}

class MethodInvocation: ASTNode {
    let receiver: ASTNode? // The object on which the method is called
    let methodName: String
    let arguments: [ASTNode]
    
    init(receiver: ASTNode?, methodName: String, arguments: [ASTNode]) {
        self.receiver = receiver
        self.methodName = methodName
        self.arguments = arguments
        super.init()
    }
}

// Usage Examples
// Defining a method within a class
let exampleGreetMethod = MethodDeclaration(
    name: "greet",
    returnType: "String",
    parameters: [MethodParameter(name: "bird", type: "Bird")],
    body: StringInterpolation(parts: [
        StringLiteral(value: "Hello, "),
        VariableReference(name: "bird.name")
    ])
)

// Adding the method to the Bird class
// birdClass.properties.append(Property(name: "greetMethod", value: greetMethod))

// Invoking the greet method
let exampleGreetInvocation = MethodInvocation(
    receiver: VariableReference(name: "pigeon"),
    methodName: "greet",
    arguments: [VariableReference(name: "parrot")]
)

// Module-level method
let exampleGreetPigeonMethod = MethodDeclaration(
    name: "greetPigeon",
    returnType: "String",
    parameters: [MethodParameter(name: "bird", type: "Bird")],
    body: MethodInvocation(
        receiver: VariableReference(name: "bird"),
        methodName: "greet",
        arguments: [VariableReference(name: "pigeon")]
    )
)

// Calling a module-level method
let exampleGreetPigeonInvocation = MethodInvocation(
    receiver: nil, // In case of global functions, receiver might be nil or a module reference
    methodName: "greetPigeon",
    arguments: [VariableReference(name: "parrot")]
)

// Defining a class
let exampleBirdClass = ClassDeclaration(
    name: "Bird",
    properties: [
        ClassProperty(name: "name", type: StringLiteralType(value: "Pigeon")),
        ClassProperty(name: "taxonomy", type: StringLiteralType(value: "Taxonomy"), isHidden: true)
    ]
)

let exampleTaxonomyClass = ClassDeclaration(
    name: "Taxonomy",
    properties: [
        ClassProperty(name: "species", type: StringLiteralType(value: ""))
    ]
)

// Creating an instance of a class
let examplePigeonInstance = ClassInstanceCreation(
    className: "Bird",
    propertyValues: [
        "name": StringLiteral(value: "Common wood pigeon"),
        "taxonomy": ObjectLiteral(properties: [
            "species": Property(name: "species", value: StringLiteral(value: "Columba palumbus"))
        ])
    ]
)

// Class Inheritance
let parentBirdClass = ClassDeclaration(
    name: "ParentBird",
    superClass: exampleBirdClass,
    properties: [
        ClassProperty(name: "kids", type: StringLiteralType(value: ""))
    ]
)

let pigeonParentInstance = ClassInstanceCreation(
    className: "ParentBird",
    propertyValues: [
        "name": StringLiteral(value: "Old Pigeon"),
        "kids": ListLiteral(elements: [StringLiteral(value: "Pigeon Jr."), StringLiteral(value: "Teen Pigeon")])
    ]
)

