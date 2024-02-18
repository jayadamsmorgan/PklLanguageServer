import Foundation

class ObjectLiteral: ASTNode {
    var properties: [String: ASTNode]
    
    init(properties: [String: ASTNode]) {
        self.properties = properties
        super.init()
    }
}

class Property: ASTNode {
    let name: String
    let value: ASTNode
    let isHidden: Bool
    let isLocal: Bool
    
    init(name: String, value: ASTNode, isHidden: Bool = false, isLocal: Bool = false) {
        self.name = name
        self.value = value
        self.isHidden = isHidden
        self.isLocal = isLocal
        super.init()
    }
}

class ObjectAmendment: ASTNode {
    let baseObject: ASTNode
    let amendedProperties: [String: ASTNode]
    
    init(baseObject: ASTNode, amendedProperties: [String: ASTNode]) {
        self.baseObject = baseObject
        self.amendedProperties = amendedProperties
        super.init()
    }
}

class LateBindingProperty: Property {
    // Inherits everything from Property, but signifies the intent for late binding
}

protocol ObjectTransformation: ASTNode {
    var targetObject: ASTNode { get set }
}

class ObjectToMapTransformation: ASTNode, ObjectTransformation {
    var targetObject: ASTNode
    
    init(targetObject: ASTNode) {
        self.targetObject = targetObject
        super.init()
    }
}

class ObjectToDynamicTransformation: ASTNode, ObjectTransformation {
    var targetObject: ASTNode
    
    init(targetObject: ASTNode) {
        self.targetObject = targetObject
        super.init()
    }
}

// Usage Examples
// Defining a simple object
let dodoObject = ObjectLiteral(properties: [
    "name": Property(name: "name", value: StringLiteral(value: "Dodo")),
    "extinct": Property(name: "extinct", value: BooleanLiteral(value: true))
])

// Amending an object
let amendedDodo = ObjectAmendment(baseObject: dodoObject, amendedProperties: [
    "name": Property(name: "name", value: StringLiteral(value: "Galápagos tortoise")),
    "taxonomy": ObjectLiteral(properties: [
        "`class`": Property(name: "`class`", value: StringLiteral(value: "Reptilia"))
    ])
])

// Transforming an object
let dodoToMap = ObjectToMapTransformation(targetObject: dodoObject)
let dodoToDynamic = ObjectToDynamicTransformation(targetObject: dodoObject)

