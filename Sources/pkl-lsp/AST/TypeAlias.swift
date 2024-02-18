import Foundation

class TypeAliasDeclaration: ASTNode {
    let name: String
    let targetType: ASTNode
    let typeParameters: [String] // Optional, for generic type aliases
    
    init(name: String, targetType: ASTNode, typeParameters: [String] = []) {
        self.name = name
        self.targetType = targetType
        self.typeParameters = typeParameters
        super.init()
    }
}

class TypeAliasUsage: ASTNode {
    let aliasName: String
    let typeArguments: [ASTNode] // Optional, for instantiating generic type aliases
    
    init(aliasName: String, typeArguments: [ASTNode] = []) {
        self.aliasName = aliasName
        self.typeArguments = typeArguments
        super.init()
    }
}

// Usage Examples
// Defining a type alias for an email address
let emailAddressAlias = TypeAliasDeclaration(
    name: "EmailAddress",
    targetType: TypeConstraint(
        constraint: RegexLiteral(pattern: #".+@.+"#)
    )
)


