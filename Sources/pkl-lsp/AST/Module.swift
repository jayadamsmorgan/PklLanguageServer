import Foundation
import LanguageServerProtocol

class PklModule: ASTNode {
    var contents: [ASTNode]

    override var children: [ASTNode]? { get { contents } set { contents = newValue ?? [] } }

    init(contents: [ASTNode], range: ASTRange, importDepth: Int, document: Document) {
        self.contents = contents
        super.init(range: range, importDepth: importDepth, document: document)
    }

    override public func diagnosticErrors() -> [ASTDiagnosticError]? {
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
    var moduleClause: PklModuleClause?
    var extendsOrAmends: PklModuleImport?

    override var children: [ASTNode]? {
        get {
            var children: [ASTNode] = []
            if let moduleClause {
                children.append(moduleClause)
            }
            if let extendsOrAmends {
                children.append(extendsOrAmends)
            }
            return children
        }
        set {
            if let newValue {
                for child in newValue {
                    if let moduleClause = child as? PklModuleClause {
                        self.moduleClause = moduleClause
                    } else if let extendsOrAmends = child as? PklModuleImport {
                        self.extendsOrAmends = extendsOrAmends
                    }
                }
            }
        }
    }

    init(moduleClause: PklModuleClause? = nil, extendsOrAmends: PklModuleImport? = nil,
         range: ASTRange, importDepth: Int, document: Document)
    {
        self.moduleClause = moduleClause
        self.extendsOrAmends = extendsOrAmends
        super.init(range: range, importDepth: importDepth, document: document)
    }

    override public func diagnosticErrors() -> [ASTDiagnosticError]? {
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
    var name: PklIdentifier?

    override var children: [ASTNode]? {
        get {
            if let name {
                return [name]
            }
            return nil
        }
        set {
            if let newValue {
                for child in newValue {
                    if let name = child as? PklIdentifier {
                        self.name = name
                    }
                }
            }
        }
    }

    init(name: PklIdentifier?, range: ASTRange, importDepth: Int, document: Document) {
        self.name = name
        super.init(range: range, importDepth: importDepth, document: document)
    }

    override public func diagnosticErrors() -> [ASTDiagnosticError]? {
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
    var path: PklStringLiteral
    var documentToImport: Document?

    var module: PklModule?

    var type: PklModuleImportType?

    override var children: [ASTNode]? {
        get {
            var children: [ASTNode] = []
            children.append(path)
            if let module {
                children.append(module)
            }
            return children
        }
        set {
            if let newValue {
                for child in newValue {
                    if let path = child as? PklStringLiteral {
                        self.path = path
                    } else if let module = child as? PklModule {
                        self.module = module
                    }
                }
            }
        }
    }

    init(module: PklModule?, range: ASTRange, path: PklStringLiteral,
         importDepth: Int, document: Document, documentToImport: Document? = nil, type: PklModuleImportType)
    {
        self.module = module
        self.documentToImport = documentToImport
        self.path = path
        self.type = type
        super.init(range: range, importDepth: importDepth, document: document)
    }

    override public func diagnosticErrors() -> [ASTDiagnosticError]? {
        if type == .error {
            return [ASTDiagnosticError("Provide either extends or amends", .error, range)]
        }
        // if documentToImport == nil {
        //     return [ASTDiagnosticError("Module cannot be found", .error, range)]
        // }
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
