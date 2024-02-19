import Foundation

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

