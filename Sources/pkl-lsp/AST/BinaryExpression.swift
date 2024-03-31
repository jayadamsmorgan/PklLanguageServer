import Foundation
import LanguageServerProtocol

enum PklBinaryOperatorType: String, CaseIterable {
    case POW
    case MULT
    case DIV
    case INT_DIV
    case MOD
    case PLUS
    case MINUS
    case LT
    case GT
    case LTE
    case GTE
    case IS
    case AS
    case EQ_EQ
    case NOT_EQ
    case AND
    case OR
    case PIPE
    case NULL_COALESCE
}

class PklBinaryOperator: ASTNode {
    var type: PklBinaryOperatorType

    init(type: PklBinaryOperatorType, range: ASTRange, importDepth: Int, document: Document) {
        self.type = type
        super.init(range: range, importDepth: importDepth, document: document)
    }

    override public func diagnosticErrors() -> [ASTDiagnosticError]? {
        nil
    }
}

class PklBinaryExpression: ASTNode {
    var binaryOperator: PklBinaryOperator?
    var leftSide: ASTNode?
    var rightSide: ASTNode?

    override var children: [ASTNode]? {
        get {
            var children: [ASTNode] = []
            if let binaryOperator {
                children.append(binaryOperator)
            }
            if let leftSide {
                children.append(leftSide)
            }
            if let rightSide {
                children.append(rightSide)
            }
            return children
        } set {
            if let newValue {
                for child in newValue {
                    if let binaryOperator = child as? PklBinaryOperator {
                        self.binaryOperator = binaryOperator
                    } else if leftSide == nil {
                        leftSide = child
                    } else if rightSide == nil {
                        rightSide = child
                    }
                }
            }
        }
    }

    init(binaryOperator: PklBinaryOperator, leftSide: ASTNode?, rightSide: ASTNode?,
         range: ASTRange, importDepth: Int, document: Document)
    {
        self.leftSide = leftSide
        self.rightSide = rightSide
        self.binaryOperator = binaryOperator
        super.init(range: range, importDepth: importDepth, document: document)
    }

    override public func diagnosticErrors() -> [ASTDiagnosticError]? {
        var errors: [ASTDiagnosticError] = []
        if binaryOperator == nil {
            errors.append(ASTDiagnosticError("Provide binary operator", .error, range))
        }
        if leftSide == nil || rightSide == nil {
            errors.append(ASTDiagnosticError("Incorrect binary expression", .error, range))
        }
        if let leftSideErrors = leftSide?.diagnosticErrors() {
            errors.append(contentsOf: leftSideErrors)
        }
        if let rightSideErrors = rightSide?.diagnosticErrors() {
            errors.append(contentsOf: rightSideErrors)
        }
        return errors.count > 0 ? errors : nil
    }
}
