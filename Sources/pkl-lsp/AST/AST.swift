import Foundation
import LanguageServerProtocol

public protocol IdentifiableNode {
    var uniqueID: UUID { get }
}

extension IdentifiableNode where Self: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(uniqueID)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.uniqueID == rhs.uniqueID
    }
}

public protocol ASTNode: IdentifiableNode, Hashable, ASTEvaluation {
    var positionStart: Position { get set }
    var positionEnd: Position { get set }
}

public protocol ASTEvaluation {
    func error() -> ASTEvaluationError? // Returns diagnostic error if AST is failing evaluation
}

public struct ASTEvaluationError {
    let error: String
    let positionStart: Position
    let positionEnd: Position

    init(_ error: String, _ positionStart: Position, _ positionEnd: Position) {
        self.error = error
        self.positionStart = positionStart
        self.positionEnd = positionEnd
    }
}


