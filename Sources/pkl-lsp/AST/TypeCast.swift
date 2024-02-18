import Foundation

class TypeCastExpression: ASTNode {
    let operand: ASTNode
    let targetType: ASTNode // TargetType can represent simple types or more complex type expressions
    
    init(operand: ASTNode, targetType: ASTNode) {
        self.operand = operand
        self.targetType = targetType
        super.init()
    }
}

