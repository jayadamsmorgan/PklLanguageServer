import Foundation

class MappingLiteral: ASTNode {
    var entries: [MappingEntry]
    var defaultValue: ASTNode?
    
    init(entries: [MappingEntry], defaultValue: ASTNode? = nil) {
        self.entries = entries
        self.defaultValue = defaultValue
        super.init()
    }
}

class MappingEntry: ASTNode {
    let key: ASTNode // Note: Keys are eagerly evaluated
    let value: ASTNode // Values are lazily evaluated
    
    init(key: ASTNode, value: ASTNode) {
        self.key = key
        self.value = value
        super.init()
    }
}

class MappingAmendment: ASTNode {
    let baseMapping: ASTNode
    let amendments: [ASTNode: ASTNode] // Key is ASTNode for flexibility in representing keys
    
    init(baseMapping: ASTNode, amendments: [ASTNode: ASTNode]) {
        self.baseMapping = baseMapping
        self.amendments = amendments
        super.init()
    }
}

protocol MappingTransformation: ASTNode {
    var targetMapping: ASTNode { get set }
}

class MappingToMapTransformation: ASTNode, MappingTransformation {
    var targetMapping: ASTNode
    
    init(targetMapping: ASTNode) {
        self.targetMapping = targetMapping
        super.init()
    }
}

class MapToMappingTransformation: ASTNode, MappingTransformation {
    var targetMapping: ASTNode
    
    init(targetMapping: ASTNode) {
        self.targetMapping = targetMapping
        super.init()
    }
}

class LocalMappingProperty: ASTNode {
    let name: String
    let value: ASTNode
    
    init(name: String, value: ASTNode) {
        self.name = name
        self.value = value
        super.init()
    }
}

// Usage Examples
// Defining a simple mapping
let birdMapping = MappingLiteral(entries: [
    MappingEntry(key: StringLiteral(value: "Pigeon"), value: ObjectLiteral(properties: [
        "lifespan": Property(name: "lifespan", value: IntLiteral(value: "8")),
        "diet": Property(name: "diet", value: StringLiteral(value: "Seeds"))
    ])),
    MappingEntry(key: StringLiteral(value: "Parrot"), value: ObjectLiteral(properties: [
        "lifespan": Property(name: "lifespan", value: IntLiteral(value: "20")),
        "diet": Property(name: "diet", value: StringLiteral(value: "Berries"))
    ]))
])

// Amending a mapping
let amendedBirdMapping = MappingAmendment(baseMapping: birdMapping, amendments: [
    StringLiteral(value: "Pigeon"): ObjectLiteral(properties: [
        "diet": Property(name: "diet", value: StringLiteral(value: "Worms"))
    ]),
    StringLiteral(value: "Parrot"): ObjectLiteral(properties: [
        "lifespan": Property(name: "lifespan", value: IntLiteral(value: "25"))
    ])
])

// Transforming a mapping to a map and back
let birdToMap = MappingToMapTransformation(targetMapping: birdMapping)
let birdToMapping = MapToMappingTransformation(targetMapping: birdToMap.targetMapping)

