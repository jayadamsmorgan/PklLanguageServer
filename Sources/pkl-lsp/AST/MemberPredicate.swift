import Foundation

class MemberPredicate: ASTNode {
    let condition: ASTNode
    let amendments: [ASTNode]
    
    init(condition: ASTNode, amendments: [ASTNode]) {
        self.condition = condition
        self.amendments = amendments
        super.init()
    }
}

