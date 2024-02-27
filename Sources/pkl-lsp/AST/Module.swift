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

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        for content in contents {
            if let errors = content.diagnosticErrors() {
                return errors
            }
        }
        return nil
    }
}
