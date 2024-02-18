import Foundation

class WhenGenerator: ASTNode {
    let condition: ASTNode
    let trueBranch: [ASTNode]
    let falseBranch: [ASTNode]?
    
    init(condition: ASTNode, trueBranch: [ASTNode], falseBranch: [ASTNode]? = nil) {
        self.condition = condition
        self.trueBranch = trueBranch
        self.falseBranch = falseBranch
        super.init()
    }
}

// Usage Example: Object Literal with When Generator
let parrotWithSinging = ObjectLiteral(properties: [
    "lifespan": IntLiteral(value: "20"),
    "isSinger": WhenGenerator(
        condition: VariableReference(name: "isSinger"),
        trueBranch: [
            VariableDeclaration(name: "hobby", value: StringLiteral(value: "\"singing\"")),
            VariableDeclaration(name: "idol", value: StringLiteral(value: "\"Frank Sinatra\""))
        ]
    )
])

// Usage Example: Listing Literal with When Generator
let abilitiesListing = ListingLiteral(elements: [
    StringLiteral(value: "\"chirping\""),
    WhenGenerator(
        condition: VariableReference(name: "isSinger"),
        trueBranch: [StringLiteral(value: "\"singing\"")],
        falseBranch: nil
    ),
    StringLiteral(value: "\"whistling\"")
])

// Usage Example: Mapping Literal with When Generator
let abilitiesByBirdMapping = MappingLiteral(entries: [
    MappingEntry(key: StringLiteral(value: "Barn owl"), value: StringLiteral(value: "\"hooing\"")),
    MappingEntry(key: StringLiteral(value: "Parrot"), value: WhenGenerator(
        condition: VariableReference(name: "isSinger"),
        trueBranch: [VariableDeclaration(name: "\"Parrot\"", value: StringLiteral(value: "\"singing\""))],
        falseBranch: [VariableDeclaration(name: "\"Parrot\"", value: StringLiteral(value: "\"whistling\""))]
    )
)])

