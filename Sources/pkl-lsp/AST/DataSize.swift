import Foundation

enum DataSizeUnit: String {
    case b = "bytes"
    case kb = "kilobytes"
    case mb = "megabytes"
    case gb = "gigabytes"
    case tb = "terabytes"
    case pb = "petabytes"
    case kib = "kibibytes"
    case mib = "mebibytes"
    case gib = "gibibytes"
    case tib = "tebibytes"
    case pib = "pebibytes"
}

class DataSizeLiteral: ASTNode {
    let value: ASTNode // Can be NumberLiteral, FloatLiteral, or an expression resulting in a Number
    let unit: DataSizeUnit
    
    init(value: ASTNode, unit: DataSizeUnit) {
        self.value = value
        self.unit = unit
        super.init()
    }
}

class DataSizeOperation: ASTNode {
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
let exampleDataSize1 = DataSizeLiteral(value: IntLiteral(value: "5"), unit: .mb)
let exampleDataSize2 = DataSizeLiteral(value: FloatLiteral(value: "5.13"), unit: .mb)
let exampleNegativeDataSize = DataSizeLiteral(value: IntLiteral(value: "-5"), unit: .mb)

// DataSize Comparison
let exampleDataSizeComparison1 = DataSizeOperation(left: exampleDataSize1, binaryOperator: .comparison(.equal), right: DataSizeLiteral(value: IntLiteral(value: "3"), unit: .kib))

// DataSize Arithmetic
let exampleDataSizeResult1 = DataSizeOperation(left: exampleDataSize1, binaryOperator: .addition, right: DataSizeLiteral(value: IntLiteral(value: "3"), unit: .kib))

