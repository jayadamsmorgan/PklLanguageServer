import Foundation

class FunctionLiteral: ASTNode {
    var parameters: [String]
    var returnType: ASTNode?
    var body: ASTNode

    init(parameters: [String], returnType: ASTNode?, body: ASTNode) {
        self.parameters = parameters
        self.returnType = returnType
        self.body = body
        super.init()
    }
}

