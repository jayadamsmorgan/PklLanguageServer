import Foundation

class ForGenerator: ASTNode {
    let variableName: String
    let iterable: ASTNode
    let body: [ASTNode]
    let keyName: String?
    
    // For generators iterating over values
    init(variableName: String, iterable: ASTNode, body: [ASTNode]) {
        self.variableName = variableName
        self.iterable = iterable
        self.body = body
        self.keyName = nil
        super.init()
    }
    
    // For generators iterating over key-value pairs
    init(keyName: String, variableName: String, iterable: ASTNode, body: [ASTNode]) {
        self.keyName = keyName
        self.variableName = variableName
        self.iterable = iterable
        self.body = body
        super.init()
    }
}

// Usage Example: Generating objects based on a list of names
let exampleNamesList = ListLiteral(elements: [StringLiteral(value: "Pigeon"), StringLiteral(value: "Barn owl"), StringLiteral(value: "Parrot")])

let exampleBirdsObject = ObjectLiteral(properties: [
    "_name" : ForGenerator(variableName: "_name", iterable: exampleNamesList, body: [
        ObjectLiteral(properties: [
            "name" : VariableDeclaration(name: "name", value: VariableReference(name: "_name")),
            "lifespan" : VariableDeclaration(name: "lifespan", value: IntLiteral(value: "42"))
        ])
    ])
])

// Usage Example: Generating object entries based on a map of names and lifespans
let exampleNamesAndLifespansMap = MapLiteral(entries: [
    (StringLiteral(value: "Pigeon"), IntLiteral(value: "8")),
    (StringLiteral(value: "Barn owl"), IntLiteral(value: "15")),
    (StringLiteral(value: "Parrot"), IntLiteral(value: "20"))
])

let exampleBirdsByNameObject = ObjectLiteral(properties: [
    "_name" : ForGenerator(keyName: "_name", variableName: "_lifespan", iterable: exampleNamesAndLifespansMap, body: [
        ObjectLiteral(properties: [
            "name" : VariableDeclaration(name: "name", value: VariableReference(name: "_name")),
            "lifespan" : VariableDeclaration(name: "lifespan", value: VariableReference(name: "_lifespan"))
        ])
    ])
])
