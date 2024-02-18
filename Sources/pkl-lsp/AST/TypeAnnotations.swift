import Foundation

class TypeAnnotation: ASTNode {
    let type: ASTNode
    let constraints: [ASTNode]?
    
    init(type: ASTNode, constraints: [ASTNode]? = nil) {
        self.type = type
        self.constraints = constraints
        super.init()
    }
}

class TypeConstraint: ASTNode {
    let constraint: ASTNode
    
    init(constraint: ASTNode) {
        self.constraint = constraint
        super.init()
    }
}

class UnionType: ASTNode {
    let types: [ASTNode]
    
    init(types: [ASTNode]) {
        self.types = types
        super.init()
    }
}

class GenericType: ASTNode {
    let baseType: String
    let typeParameters: [ASTNode]
    
    init(baseType: String, typeParameters: [ASTNode]) {
        self.baseType = baseType
        self.typeParameters = typeParameters
        super.init()
    }
}

class StringLiteralType: ASTNode {
    let value: String
    
    init(value: String) {
        self.value = value
        super.init()
    }
}

class NullableType: ASTNode {
    let type: ASTNode
    
    init(type: ASTNode) {
        self.type = type
        super.init()
    }
}

