import Foundation

class StringLiteral: ASTNode {
    let value: String
    let isMultiline: Bool
    let delimiterCount: Int // For custom string delimiters
    
    init(value: String, isMultiline: Bool = false, delimiterCount: Int = 0) {
        self.value = value
        self.isMultiline = isMultiline
        self.delimiterCount = delimiterCount
        super.init()
    }
}

class StringInterpolation: ASTNode {
    let parts: [ASTNode] // Parts can be StringLiteral or expressions to be evaluated and converted to String
    
    init(parts: [ASTNode]) {
        self.parts = parts
        super.init()
    }
}

class StringConcatenation: ASTNode {
    let left: ASTNode
    let right: ASTNode
    
    init(left: ASTNode, right: ASTNode) {
        self.left = left
        self.right = right
        super.init()
    }
}

class StringOperation: ASTNode {
    enum OperationType {
        case length
        case reverse
        case contains(String)
        case trim
    }
    
    let operation: OperationType
    let target: ASTNode // The StringLiteral or variable containing the string
    
    init(target: ASTNode, operation: OperationType) {
        self.target = target
        self.operation = operation
        super.init()
    }
}

// Usage Examples
let simpleString = StringLiteral(value: "Hello, World!")
let multilineString = StringLiteral(value: """
Although the Dodo is extinct,
the species will be remembered.
""", isMultiline: true)
let interpolatedString = StringInterpolation(parts: [
    StringLiteral(value: "Hi, "),
    VariableReference(name: "name"),
    StringLiteral(value: "!")
])
let concatenatedString = StringConcatenation(left: StringLiteral(value: "abc"), right: StringLiteral(value: "def"))
let stringOperation = StringOperation(target: VariableReference(name: "dodo"), operation: .contains("alive"))

