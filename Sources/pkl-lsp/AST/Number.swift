import Foundation

enum PklNumberType {
    case int
    case uint
    case float
    case int8
    case int16
    case int32
    case uint8
    case uint16
    case uint32
}

class PklFunctionCall : ASTNode {
    var name: String
    var functionReturn: ASTNode?
    var arguments: [ASTNode]

    init(name: String, arguments: [ASTNode], functionReturn: ASTNode? = nil) {
        self.name = name
        self.arguments = arguments
        self.functionReturn = functionReturn
        super.init()
    }
}

class PklNumberConstraintFunctionCall : PklFunctionCall {
    var upperBound: PklNumberLiteral
    var lowerBound: PklNumberLiteral?

    init(name: String, arguments: [ASTNode], upperBound: PklNumberLiteral, lowerBound: PklNumberLiteral? = nil) {
        self.upperBound = upperBound
        self.lowerBound = lowerBound
        super.init(name: name, arguments: arguments)
    }

}

class PklIntLiteral : PklNumberLiteral {
    init(value: String? = nil) {
        super.init(value: value, type: .int)
    }
}

class PklFloatLiteral : PklNumberLiteral {
    init(value: String? = nil) {
        super.init(value: value, type: .float)
    }
}

class PklNumberLiteral : ASTNode {
    var type: PklNumberType
    var value: String?
    
    init(value: String? = nil, type: PklNumberType) {
        self.type = type
        self.value = value
        super.init()
    }
}

class PklStringLiteral : ASTNode {
    var value: String?

    init(value: String? = nil) {
        self.value = value
        super.init()
    }
}

