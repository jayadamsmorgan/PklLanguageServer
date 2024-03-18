import Foundation

struct PklVariable: ASTNode {
    let uniqueID: UUID = .init()

    var range: ASTRange
    var importDepth: Int
    var document: Document

    let identifier: PklIdentifier?
    let reference: (any ASTNode)?

    var children: [any ASTNode]? {
        var children: [any ASTNode] = []
        if let reference {
            children.append(reference)
        }
        if let identifier {
            children.append(identifier)
        }
        return children
    }

    init(identifier: PklIdentifier?, reference: (any ASTNode)?, range: ASTRange, importDepth: Int, document: Document) {
        self.identifier = identifier
        self.reference = reference
        self.range = range
        self.importDepth = importDepth
        self.document = document
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        if reference == nil {
            let error = ASTDiagnosticError("Unknown reference to \(identifier?.value ?? "nil")", .error, range)
            return [error]
        }
        return nil
    }
}
