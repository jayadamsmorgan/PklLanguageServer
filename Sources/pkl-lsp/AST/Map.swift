import Foundation

class MapLiteral: ASTNode {
    var entries: [(key: ASTNode, value: ASTNode)]
    
    init(entries: [(key: ASTNode, value: ASTNode)]) {
        self.entries = entries
        super.init()
    }
}

class MapMerge: ASTNode {
    let maps: [ASTNode]
    
    init(maps: [ASTNode]) {
        self.maps = maps
        super.init()
    }
}

class MapAccess: ASTNode {
    let map: ASTNode
    let key: ASTNode
    
    init(map: ASTNode, key: ASTNode) {
        self.map = map
        self.key = key
        super.init()
    }
}

class MapOperation: ASTNode {
    enum OperationType {
        case containsKey, containsValue, isEmpty, length, getOrNull
    }
    
    let operation: OperationType
    let map: ASTNode
    let argument: ASTNode?
    
    init(operation: OperationType, map: ASTNode, argument: ASTNode? = nil) {
        self.operation = operation
        self.map = map
        self.argument = argument
        super.init()
    }
}

// Usage Examples
// Constructing maps
let emptyMap = MapLiteral(entries: [])
let simpleMap = MapLiteral(entries: [(IntLiteral(value: "1"), StringLiteral(value: "\"one\"")), (IntLiteral(value: "2"), StringLiteral(value: "\"two\""))])
let heterogenousMap = MapLiteral(entries: [(IntLiteral(value: "1"), StringLiteral(value: "\"x\"")), (IntLiteral(value: "2"), IntLiteral(value: "5")), (IntLiteral(value: "3"), simpleMap)])

// Merging maps
let mergedMap = MapMerge(maps: [simpleMap, MapLiteral(entries: [(IntLiteral(value: "3"), StringLiteral(value: "\"three\""))])])

// Accessing a value by key
let valueAccess = MapAccess(map: simpleMap, key: IntLiteral(value: "2"))

// Map operations
let containsParrot = MapOperation(operation: .containsKey, map: simpleMap, argument: StringLiteral(value: "\"Parrot\""))
let mapLength = MapOperation(operation: .length, map: simpleMap)
let getFalconOrNull = MapOperation(operation: .getOrNull, map: simpleMap, argument: StringLiteral(value: "\"Falcon\""))

