import Foundation
import LanguageServerProtocol

class PklModule : ASTNode {

    var uniqueID: UUID = UUID()

    var positionEnd: Position
    var positionStart: Position

    var contents: [any ASTNode]

    init(contents: [any ASTNode], positionStart: Position, positionEnd: Position) {
        self.contents = contents
        self.positionStart = positionStart
        self.positionEnd = positionEnd
    }

    func error() -> ASTEvaluationError? {
        for content in contents {
            if let error = content.error() {
                return error
            }
        }
        return nil
    }
}
