import Foundation
import LanguageServerProtocol

struct PklIdentifier: ASTNode {
    let uniqueID: UUID = .init()

    var positionStart: Position
    var positionEnd: Position

    var value: String

    var children: [any ASTNode]? = nil

    init(value: String, positionStart: Position, positionEnd: Position) {
        self.value = value
        self.positionStart = positionStart
        self.positionEnd = positionEnd
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        nil
    }
}
