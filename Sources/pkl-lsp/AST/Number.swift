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

