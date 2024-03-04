import Foundation
import LanguageServerProtocol

public protocol IdentifiableNode {
    var uniqueID: UUID { get }
}

public extension IdentifiableNode where Self: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(uniqueID)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.uniqueID == rhs.uniqueID
    }
}

public protocol ASTNode: IdentifiableNode, Hashable, ASTEvaluation {
    var positionStart: Position { get set }
    var positionEnd: Position { get set }

    var children: [any ASTNode]? { get }
}

public protocol ASTEvaluation {
    func diagnosticErrors() -> [ASTDiagnosticError]?
}

public enum ASTDiagnosticErrorSeverity {
    case warning
    case error
}

public struct ASTDiagnosticError: Hashable {
    let error: String
    let severity: ASTDiagnosticErrorSeverity
    let positionStart: Position
    let positionEnd: Position

    init(_ error: String, _ severity: ASTDiagnosticErrorSeverity, _ positionStart: Position, _ positionEnd: Position) {
        self.error = error
        self.positionStart = positionStart
        self.positionEnd = positionEnd
        self.severity = severity
    }
}
