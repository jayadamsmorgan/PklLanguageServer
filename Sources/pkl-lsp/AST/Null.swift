import Foundation
import LanguageServerProtocol

struct PklNullLiteral: ASTNode {
    let uniqueID: UUID = .init()

    var positionStart: Position
    var positionEnd: Position

    var children: [any ASTNode]? = nil

    init(positionStart: Position, positionEnd: Position) {
        self.positionStart = positionStart
        self.positionEnd = positionEnd
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        nil
    }
}
