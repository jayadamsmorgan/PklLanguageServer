import Foundation
import LanguageServerProtocol

struct PklValue : ASTNode {

    let uniqueID: UUID = UUID()

    var positionStart: Position
    var positionEnd: Position

    var value: String?

    var type: PklType?

    init(value: String? = nil, type: PklType? = nil, positionStart: Position, positionEnd: Position) {
        self.value = value
        self.positionStart = positionStart
        self.positionEnd = positionEnd
        self.type = type
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        if value != nil {
            return nil
        }
        return [ASTDiagnosticError("Provide value", .error, positionStart, positionEnd)]
    }

}
