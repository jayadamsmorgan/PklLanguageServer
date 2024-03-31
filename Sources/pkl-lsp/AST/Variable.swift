import Foundation

class PklVariable: ASTNode {
    var identifier: PklIdentifier?
    var reference: ASTNode?

    override var children: [ASTNode]? {
        get {
            var children: [ASTNode] = []
            if let reference {
                children.append(reference)
            }
            if let identifier {
                children.append(identifier)
            }
            return children
        }
        set {
            if let newValue {
                for child in newValue {
                    if let identifier = child as? PklIdentifier {
                        self.identifier = identifier
                    }
                }
            }
        }
    }

    init(identifier: PklIdentifier?, reference: ASTNode?, range: ASTRange, importDepth: Int, document: Document) {
        self.identifier = identifier
        self.reference = reference
        super.init(range: range, importDepth: importDepth, document: document)
    }

    override public func diagnosticErrors() -> [ASTDiagnosticError]? {
        if reference == nil {
            let error = ASTDiagnosticError("Unknown reference to \(identifier?.value ?? "nil")", .error, range)
            return [error]
        }
        return nil
    }
}
