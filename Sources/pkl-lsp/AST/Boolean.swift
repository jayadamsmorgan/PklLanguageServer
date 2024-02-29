import Foundation
import LanguageServerProtocol


struct PklBooleanLiteral : ASTNode {

    let uniqueID: UUID = UUID()

    var positionStart: Position
    var positionEnd: Position

    var value: Bool

    var children: [any ASTNode]? = nil

    init(value: Bool, positionStart: Position, positionEnd: Position) {
        self.value = value
        self.positionStart = positionStart
        self.positionEnd = positionEnd
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        return nil
    }
}

