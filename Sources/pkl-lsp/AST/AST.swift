import Foundation
import LanguageServerProtocol
import SwiftTreeSitter

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
    var range: ASTRange { get set }

    var children: [any ASTNode]? { get }

    var importDepth: Int { get set }

    var document: Document { get }
}

public protocol ASTEvaluation {
    func diagnosticErrors() -> [ASTDiagnosticError]?
}

public struct ASTRange: Hashable {
    let positionRange: Range<Position>
    let byteRange: Range<UInt32>

    public init(positionRange: Range<Position>, byteRange: Range<UInt32>) {
        self.positionRange = positionRange
        self.byteRange = byteRange
    }

    public init(pointRange: Range<Point>, byteRange: Range<UInt32>) {
        let positionStart = pointRange.lowerBound.toPosition()
        let positionEnd = pointRange.upperBound.toPosition()
        positionRange = positionStart ..< positionEnd
        self.byteRange = byteRange
    }

    public func getLSPRange() -> LSPRange {
        LSPRange(start: positionRange.lowerBound, end: positionRange.upperBound)
    }
}

public struct ASTDiagnosticError: Hashable {
    let message: String
    let severity: DiagnosticSeverity
    var range: ASTRange

    init(_ error: String, _ severity: DiagnosticSeverity, _ range: ASTRange) {
        message = error
        self.severity = severity
        self.range = range
    }
}
