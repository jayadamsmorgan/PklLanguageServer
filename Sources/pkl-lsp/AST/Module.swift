import Foundation
import LanguageServerProtocol

struct PklModule: ASTNode {
    var uniqueID: UUID = .init()

    var range: ASTRange
    let importDepth: Int
    let document: Document

    var contents: [any ASTNode]

    var children: [any ASTNode]? {
        contents
    }

    init(contents: [any ASTNode], range: ASTRange, importDepth: Int, document: Document) {
        self.contents = contents
        self.range = range
        self.importDepth = importDepth
        self.document = document
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        var errors: [ASTDiagnosticError] = []
        for content in contents {
            if let contentErrors = content.diagnosticErrors() {
                errors.append(contentsOf: contentErrors)
            }
        }
        return errors.count > 0 ? errors : nil
    }
}

struct PklModuleAmending: ASTNode {
    var uniqueID: UUID = .init()

    let path: PklStringLiteral
    let document: Document

    var range: ASTRange
    let importDepth: Int

    var module: PklModule

    var children: [any ASTNode]? {
        [path, module]
    }

    init(module: PklModule, range: ASTRange, path: PklStringLiteral, importDepth: Int, document: Document) {
        self.module = module
        self.range = range
        self.importDepth = importDepth
        self.document = document
        self.path = path
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        guard var moduleErrors = module.diagnosticErrors() else {
            return nil
        }
        // change range of errors to be in the context of the amending module
        moduleErrors = moduleErrors.filter { $0.severity == .error }
        moduleErrors = moduleErrors.map { error in
            if error.message.contains("In included file") {
                return error
            }
            let importedPosition = Position((error.range.positionRange.lowerBound.line + 1, error.range.positionRange.lowerBound.character / 2 + 1))
            return ASTDiagnosticError("In included file: \(path.value ?? ""): \(importedPosition): \(error.message)", error.severity, range)
        }
        return moduleErrors
    }
}
