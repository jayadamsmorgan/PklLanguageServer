import Foundation

class ListingLiteral: ASTNode {
    var elements: [ASTNode]
    var defaultElement: ASTNode?
    
    init(elements: [ASTNode], defaultElement: ASTNode? = nil) {
        self.elements = elements
        self.defaultElement = defaultElement
        super.init()
    }
}

class ListingAmendment: ASTNode {
    let baseListing: ASTNode
    let amendments: [Int: ASTNode] // Key is index for specific amendments, value is the new ASTNode for that index
    
    init(baseListing: ASTNode, amendments: [Int: ASTNode]) {
        self.baseListing = baseListing
        self.amendments = amendments
        super.init()
    }
}

protocol ListingTransformation: ASTNode {
    var targetListing: ASTNode { get set }
}

class ToListTransformation: ASTNode, ListingTransformation {
    var targetListing: ASTNode
    
    init(targetListing: ASTNode) {
        self.targetListing = targetListing
        super.init()
    }
}

class ToListingTransformation: ASTNode, ListingTransformation {
    var targetListing: ASTNode
    
    init(targetListing: ASTNode) {
        self.targetListing = targetListing
        super.init()
    }
}

class LocalProperty: ASTNode {
    let name: String
    let value: ASTNode
    
    init(name: String, value: ASTNode) {
        self.name = name
        self.value = value
        super.init()
    }
}

// Usage Examples
// Defining a simple listing
let birdListing = ListingLiteral(elements: [
    ObjectLiteral(properties: [
        "name": Property(name: "name", value: StringLiteral(value: "Pigeon")),
        "diet": Property(name: "diet", value: StringLiteral(value: "Seed"))
    ]),
    ObjectLiteral(properties: [
        "name": Property(name: "name", value: StringLiteral(value: "Parrot")),
        "diet": Property(name: "diet", value: StringLiteral(value: "Berries"))
    ])
])

// Amending a listing
let amendedBirdListing = ListingAmendment(baseListing: birdListing, amendments: [
    0: ObjectLiteral(properties: [
        "diet": Property(name: "diet", value: StringLiteral(value: "Worms"))
    ]),
    1: ObjectLiteral(properties: [
        "name": Property(name: "name", value: StringLiteral(value: "Albatross")),
        "diet": Property(name: "diet", value: StringLiteral(value: "Fish"))
    ])
])

// Transforming a listing to a list and back
let birdToList = ToListTransformation(targetListing: birdListing)
let birdToListing = ToListingTransformation(targetListing: birdToList.targetListing)

