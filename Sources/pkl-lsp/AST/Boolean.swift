import Foundation
import LanguageServerProtocol

class PklBooleanLiteral: ASTNode {

    let uniqueID: UUID = UUID()

    var positionStart: Position
    var positionEnd: Position

    var value: Bool

    init(value: Bool, positionStart: Position, positionEnd: Position) {
        self.value = value
        self.positionStart = positionStart
        self.positionEnd = positionEnd
    }

    func error() -> ASTEvaluationError? {
        return nil
    }
}
