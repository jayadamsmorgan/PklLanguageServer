import Foundation
import LanguageServerProtocol

class PklValue : ASTNode {

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

    public func error() -> ASTEvaluationError? {
        if value != nil {
            return nil
        }
        return ASTEvaluationError("Provide value", positionStart, positionEnd)
    }

}
