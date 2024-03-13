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

struct PklModuleImport: ASTNode {
    var uniqueID: UUID = .init()

    var path: PklStringLiteral
    let document: Document

    var range: ASTRange
    let importDepth: Int

    var module: PklModule?

    var children: [any ASTNode]? {
        var children: [any ASTNode] = []
        children.append(path)
        if let module {
            children.append(module)
        }
        return children
    }

    init(module: PklModule?, range: ASTRange, path: PklStringLiteral,
         importDepth: Int, document: Document)
    {
        self.module = module
        self.range = range
        self.importDepth = importDepth
        self.document = document
        self.path = path
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        guard let module else {
            return [ASTDiagnosticError("Module cannot be found", .error, range)]
        }
        guard var moduleErrors = module.diagnosticErrors() else {
            return nil
        }
        moduleErrors = moduleErrors.filter { $0.severity == .error }
        moduleErrors = moduleErrors.map { error in
            if error.message.starts(with: "In included file") {
                return ASTDiagnosticError(error.message, error.severity, range)
            }
            let importedPosition = Position((error.range.positionRange.lowerBound.line + 1, error.range.positionRange.lowerBound.character / 2 + 1))
            return ASTDiagnosticError("In included file: \(path.value ?? ""): \(importedPosition): \(error.message)", error.severity, range)
        }
        return moduleErrors
    }
}

struct PklModuleAmendingOrExtending: ASTNode {
    var uniqueID: UUID = .init()

    let path: PklStringLiteral
    let document: Document

    var extends: Bool
    var amends: Bool

    var range: ASTRange
    let importDepth: Int

    var module: PklModule?

    var children: [any ASTNode]? {
        var children: [any ASTNode] = []
        children.append(path)
        if let module {
            children.append(module)
        }
        return children
    }

    init(module: PklModule?, range: ASTRange, path: PklStringLiteral,
         importDepth: Int, document: Document, extends: Bool, amends: Bool)
    {
        self.module = module
        self.range = range
        self.importDepth = importDepth
        self.document = document
        self.path = path
        self.extends = extends
        self.amends = amends
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        if extends, amends {
            return [ASTDiagnosticError("Provide either extends or amends", .error, range)]
        }
        guard let module else {
            return [ASTDiagnosticError("Module cannot be found", .error, range)]
        }
        guard var moduleErrors = module.diagnosticErrors() else {
            return nil
        }
        moduleErrors = moduleErrors.filter { $0.severity == .error }
        moduleErrors = moduleErrors.map { error in
            if error.message.starts(with: "In included file") {
                return ASTDiagnosticError(error.message, error.severity, range)
            }
            let importedPosition = Position((error.range.positionRange.lowerBound.line + 1, error.range.positionRange.lowerBound.character / 2 + 1))
            return ASTDiagnosticError("In included file: \(path.value ?? ""): \(importedPosition): \(error.message)", error.severity, range)
        }
        return moduleErrors
    }
}
