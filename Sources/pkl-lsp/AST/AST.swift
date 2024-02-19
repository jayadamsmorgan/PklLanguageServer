import Foundation

public class ASTNode: Hashable {

    private let uniqueID = UUID()
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uniqueID)
    }
    
    public static func == (lhs: ASTNode, rhs: ASTNode) -> Bool {
        return lhs.uniqueID == rhs.uniqueID
    }
}
