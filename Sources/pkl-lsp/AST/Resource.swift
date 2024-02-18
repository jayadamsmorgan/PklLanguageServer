import Foundation

class ReadExpression: ASTNode {
    let uri: String
    let isNullable: Bool
    let isGlobbed: Bool
    
    init(uri: String, isNullable: Bool = false, isGlobbed: Bool = false) {
        self.uri = uri
        self.isNullable = isNullable
        self.isGlobbed = isGlobbed
        super.init()
    }
}

class ResourceConversion: ASTNode {
    let resource: ASTNode
    let conversionMethod: String // e.g., "toInt", "toString"
    
    init(resource: ASTNode, conversionMethod: String) {
        self.resource = resource
        self.conversionMethod = conversionMethod
        super.init()
    }
}

// Usage Examples
// Reading an environment variable
let pathRead = ReadExpression(uri: "env:PATH")

// Nullable read of an environment variable with conversion
let portRead = ResourceConversion(
    resource: ReadExpression(uri: "env:PORT", isNullable: true),
    conversionMethod: "toInt"
)

// Fallback for nullable reads
let portReadWithDefault = NullCoalescing(
    lhs: portRead,
    rhs: IntLiteral(value: "1234")
)

// Globbed read of configuration files
let configFilesRead = ReadExpression(uri: "file:config/*.cfg", isGlobbed: true)

