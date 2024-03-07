import Foundation
import LanguageServerProtocol

struct PklModule: ASTNode {
    var uniqueID: UUID = .init()

    var range: ASTRange
    let importDepth: Int

    var contents: [any ASTNode]

    var children: [any ASTNode]? {
        contents
    }

    init(contents: [any ASTNode], range: ASTRange, importDepth: Int) {
        self.contents = contents
        self.range = range
        self.importDepth = importDepth
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

struct PklModuleAmending: ASTNode {
    var uniqueID: UUID = .init()

    var range: ASTRange
    let importDepth: Int

    var module: PklModule

    var children: [any ASTNode]? {
        [module]
    }

    init(module: PklModule, range: ASTRange, importDepth: Int) {
        self.module = module
        self.range = range
        self.importDepth = importDepth
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        module.diagnosticErrors()
    }
}
