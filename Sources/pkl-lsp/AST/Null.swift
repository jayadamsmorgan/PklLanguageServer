import Foundation
import LanguageServerProtocol

class PklNullLiteral: ASTNode {

    let uniqueID: UUID = UUID()

    var positionStart: Position
    var positionEnd: Position

    init(positionStart: Position, positionEnd: Position) {
        self.positionStart = positionStart
        self.positionEnd = positionEnd
    }

    func error() -> ASTEvaluationError? {
        return nil
    }
}