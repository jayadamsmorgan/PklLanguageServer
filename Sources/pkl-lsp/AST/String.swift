import Foundation
import LanguageServerProtocol


struct PklStringLiteral : ASTNode {

    let uniqueID: UUID = UUID()

    var positionStart: Position
    var positionEnd: Position

    var value: String?

    init(value: String? = nil, positionStart: Position, positionEnd: Position) {
        self.value = value
        self.positionStart = positionStart
        self.positionEnd = positionEnd
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        if value != nil {
            return nil
        }
        return [ASTDiagnosticError("Provide string value", .error, positionStart, positionEnd)]
    }
}

