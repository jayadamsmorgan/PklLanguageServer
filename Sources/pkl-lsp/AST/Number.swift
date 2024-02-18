import Foundation

class NumberLiteral: ASTNode {
    let value: String
    let type: NumberType
    
    init(value: String, type: NumberType) {
        self.value = value
        self.type = type
        super.init()
    }
}

enum NumberType {
    case float

    case int

    case int8
    case int16
    case int32

    case uint8
    case uint16
    case uint, uint32 // UInt has the same maximum value as Int, so that makes it just an UInt32
}

class IntLiteral: ASTNode {
    let value: String
    let type: NumberType = .int

    init(value: String) {
        self.value = value
        super.init()
    }
}

class FloatLiteral: ASTNode {
    let value: String
    let type: NumberType = .float
    
    init(value: String) {
        self.value = value
        super.init()
    }
}

class SpecialFloatValue: ASTNode {
    enum ValueType {
        case nan
        case positiveInfinity
        case negativeInfinity
    }
    
    let type: ValueType
    
    init(type: ValueType) {
        self.type = type
        super.init()
    }
}

class BinaryExpression: ASTNode {
    let left: ASTNode
    let binaryOperator: BinaryOperator
    let right: ASTNode
    
    init(left: ASTNode, binaryOperator: BinaryOperator, right: ASTNode) {
        self.left = left
        self.binaryOperator = binaryOperator
        self.right = right
        super.init()
    }
}

enum BinaryOperator {
    case addition
    case subtraction
    case multiplication
    case division
    case integerDivision
    case remainder
    case exponentiation
    case comparison(ComparisonOperator)
}

enum ComparisonOperator {
    case equal
    case notEqual
    case lessThan
    case greaterThan
    case lessThanOrEqual
    case greaterThanOrEqual
}

class FiniteConstraint: ASTNode {
    let variableName: String
    let isFinite: Bool
    
    init(variableName: String, isFinite: Bool) {
        self.variableName = variableName
        self.isFinite = isFinite
        super.init()
    }
}

class RangeConstraint: ASTNode {
    let variableName: String
    let lowerBound: ASTNode
    let upperBound: ASTNode
    let type: NumberType
    
    init(variableName: String, lowerBound: ASTNode, upperBound: ASTNode, type: NumberType) {
        self.variableName = variableName
        self.lowerBound = lowerBound
        self.upperBound = upperBound
        self.type = type
        super.init()
    }
}

class NumberNotation: ASTNode {
    let literal: String
    
    init(literal: String) {
        self.literal = literal
        super.init()
    }
}

// Usage example
// This would typically be part of the parsing process, where you construct the AST from source code.
let exampleNum1 = NumberLiteral(value: "123", type: .int)
let exampleNum2 = NumberLiteral(value: "0x012AFF", type: .int)
let additionExpression = BinaryExpression(left: exampleNum1, binaryOperator: .addition, right: exampleNum2)

// To create a range constrained integer
let clientPort = RangeConstraint(variableName: "clientPort", lowerBound: NumberLiteral(value: "0", type: .int), upperBound: NumberLiteral(value: "65535", type: .int), type: .uint16)
// Float literals
let exampleFloatNum1 = FloatLiteral(value: ".23")
let exampleFloatNum2 = FloatLiteral(value: "1.23")
let exampleFloatNum3 = FloatLiteral(value: "1.23e2")
let exampleFloatNum4 = FloatLiteral(value: "1.23e-2")

// Special Float Values
let notANumber = SpecialFloatValue(type: .nan)
let positiveInfinity = SpecialFloatValue(type: .positiveInfinity)
let negativeInfinity = SpecialFloatValue(type: .negativeInfinity)

// Finite Constraint
let finiteFloat = FiniteConstraint(variableName: "x", isFinite: true)

// Range Constraint for Float
let floatRangeConstraint = RangeConstraint(variableName: "x", lowerBound: FloatLiteral(value: "0"), upperBound: FloatLiteral(value: "1e6"), type: .float)

