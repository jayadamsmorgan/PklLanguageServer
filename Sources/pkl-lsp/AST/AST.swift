import Foundation

class ASTNode: Hashable {

    private let uniqueID = UUID()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(uniqueID)
    }
    
    static func == (lhs: ASTNode, rhs: ASTNode) -> Bool {
        return lhs.uniqueID == rhs.uniqueID
    }
}
