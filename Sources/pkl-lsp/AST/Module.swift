import Foundation
import LanguageServerProtocol

class PklModule: ASTNode {
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

class PklModuleHeader: ASTNode {
    var uniqueID: UUID = .init()

    var range: ASTRange
    let importDepth: Int
    let document: Document

    var moduleClause: PklModuleClause?
    var extendsOrAmends: PklModuleImport?

    var children: [any ASTNode]? {
        var children: [any ASTNode] = []
        if let moduleClause {
            children.append(moduleClause)
        }
        if let extendsOrAmends {
            children.append(extendsOrAmends)
        }
        return children
    }

    init(moduleClause: PklModuleClause? = nil, extendsOrAmends: PklModuleImport? = nil,
         range: ASTRange, importDepth: Int, document: Document)
    {
        self.moduleClause = moduleClause
        self.extendsOrAmends = extendsOrAmends
        self.range = range
        self.importDepth = importDepth
        self.document = document
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        var errors: [ASTDiagnosticError] = []
        if let moduleClauseErrors = moduleClause?.diagnosticErrors() {
            errors.append(contentsOf: moduleClauseErrors)
        }
        if let extendsOrAmendsErrors = extendsOrAmends?.diagnosticErrors() {
            errors.append(contentsOf: extendsOrAmendsErrors)
        }
        return errors.count > 0 ? errors : nil
    }
}

class PklModuleClause: ASTNode {
    var uniqueID: UUID = .init()

    var range: ASTRange
    let importDepth: Int
    let document: Document

    var name: PklIdentifier?

    var children: [any ASTNode]? {
        if let name {
            return [name]
        }
        return nil
    }

    init(name: PklIdentifier?, range: ASTRange, importDepth: Int, document: Document) {
        self.name = name
        self.range = range
        self.importDepth = importDepth
        self.document = document
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        if name == nil {
            return [ASTDiagnosticError("Missing module path", .error, range)]
        }
        return nil
    }
}

enum PklModuleImportType {
    case amending
    case extending
    case normal
    case error
}

class PklModuleImport: ASTNode {
    var uniqueID: UUID = .init()

    let path: PklStringLiteral
    let document: Document

    var range: ASTRange
    let importDepth: Int

    var module: PklModule?

    var type: PklModuleImportType?

    var exists: Bool

    var children: [any ASTNode]? {
        var children: [any ASTNode] = []
        children.append(path)
        if let module {
            children.append(module)
        }
        return children
    }

    init(module: PklModule?, range: ASTRange, path: PklStringLiteral,
         importDepth: Int, document: Document, type: PklModuleImportType, exists: Bool)
    {
        self.module = module
        self.range = range
        self.importDepth = importDepth
        self.document = document
        self.path = path
        self.type = type
        self.exists = exists
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        if type == .error {
            return [ASTDiagnosticError("Provide either extends or amends", .error, range)]
        }
        if !exists {
            return [ASTDiagnosticError("Module cannot be found", .error, range)]
        }
        guard var moduleErrors = module?.diagnosticErrors() else {
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
