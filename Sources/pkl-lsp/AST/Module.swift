import Foundation
import LanguageServerProtocol

struct PklModule: ASTNode {
    var uniqueID: UUID = .init()

    var range: ASTRange

    var contents: [any ASTNode]

    var children: [any ASTNode]? {
        contents
    }

    init(contents: [any ASTNode], range: ASTRange) {
        self.contents = contents
        self.range = range
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
