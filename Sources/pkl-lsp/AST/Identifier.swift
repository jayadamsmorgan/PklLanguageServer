import Foundation
import LanguageServerProtocol


struct PklIdentifier : ASTNode {

    let uniqueID: UUID = UUID()

    var positionStart: Position
    var positionEnd: Position

    var value: String

    init(value: String, positionStart: Position, positionEnd: Position) {
        self.value = value
        self.positionStart = positionStart
        self.positionEnd = positionEnd
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        return nil
    }

}

