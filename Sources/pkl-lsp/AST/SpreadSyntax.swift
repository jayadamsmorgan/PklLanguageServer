class SpreadSyntax: ASTNode {
    let iterable: ASTNode
    
    init(iterable: ASTNode) {
        self.iterable = iterable
        super.init()
    }
}

// NullableSpreadSyntax class for nullable spreading
class NullableSpreadSyntax: ASTNode {
    let iterable: ASTNode
    
    init(iterable: ASTNode) {
        self.iterable = iterable
        super.init()
    }
}

// Example usage of SpreadSyntax and NullableSpreadSyntax
// Assuming a context where `entries1`, `elements1`, and `properties1` are defined elsewhere

class ObjectWithSpreads: ASTNode {
    var members: [ASTNode]
    
    init(members: [ASTNode]) {
        self.members = members
        super.init()
    }
}

// Constructing examples of spreading entries, elements, and properties
let entriesSpread = ObjectWithSpreads(members: [
    SpreadSyntax(iterable: VariableReference(name: "entries1"))
])

let elementsSpread = ObjectWithSpreads(members: [
    SpreadSyntax(iterable: VariableReference(name: "elements1"))
])

let propertiesSpread = ObjectWithSpreads(members: [
    SpreadSyntax(iterable: VariableReference(name: "properties1"))
])

// Example of nullable spreading
let nullableEntriesSpread = ObjectWithSpreads(members: [
    NullableSpreadSyntax(iterable: VariableReference(name: "optionalEntries"))
])
