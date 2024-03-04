import Foundation
import LanguageServerProtocol

struct PklModule: ASTNode {
    var uniqueID: UUID = .init()

    var positionEnd: Position
    var positionStart: Position

    var contents: [any ASTNode]

    var children: [any ASTNode]? {
        contents
    }

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
