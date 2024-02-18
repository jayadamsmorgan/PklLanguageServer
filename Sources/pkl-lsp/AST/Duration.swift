import Foundation

enum DurationUnit: String {
    case ns = "nanoseconds"
    case us = "microseconds"
    case ms = "milliseconds"
    case s = "seconds"
    case min = "minutes"
    case h = "hours"
    case d = "days"
}

class DurationLiteral: ASTNode {
    let value: ASTNode // Can be NumberLiteral, FloatLiteral, or an expression resulting in a Number
    let unit: DurationUnit
    
    init(value: ASTNode, unit: DurationUnit) {
        self.value = value
        self.unit = unit
        super.init()
    }
}

class DurationOperation: ASTNode {
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

// Usage Examples
let exampleDuration1 = DurationLiteral(value: IntLiteral(value: "5"), unit: .min)
let exampleDuration2 = DurationLiteral(value: FloatLiteral(value: "5.13"), unit: .min)
let exampleNegativeDuration = DurationLiteral(value: IntLiteral(value: "-5"), unit: .min)

let exampleDurationComparison1 = DurationOperation(left: exampleDuration1, binaryOperator: .comparison(.equal), right: DurationLiteral(value: IntLiteral(value: "3"), unit: .s))

let exampleDurationResult1 = DurationOperation(left: exampleDuration1, binaryOperator: .addition, right: DurationLiteral(value: IntLiteral(value: "3"), unit: .s))

