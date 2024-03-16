import Foundation
import LanguageServerProtocol

enum PklBinaryOperatorType: String, CaseIterable {
    case addition
    case subtraction
    case equals
    case notEquals
    case greater
    case greaterOrEquals
    case less
    case lessOrEquals
    case muliplication
    case division
    case modulus
    case exponentiation
    case `is`
    case or
    case and
}

struct PklBinaryOperator: ASTNode {
    var uniqueID: UUID = .init()

    var range: ASTRange
    var importDepth: Int
    var document: Document

    var type: PklBinaryOperatorType

    var children: [any ASTNode]? {
        nil
    }

    init(type: PklBinaryOperatorType, range: ASTRange, importDepth: Int, document: Document) {
        self.range = range
        self.importDepth = importDepth
        self.document = document
        self.type = type
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        nil
    }
}

struct PklBinaryExpression: ASTNode {
    var uniqueID: UUID = .init()

    var range: ASTRange
    var importDepth: Int
    var document: Document

    var binaryOperator: PklBinaryOperator?
    var leftSide: (any ASTNode)?
    var rightSide: (any ASTNode)?

    var children: [any ASTNode]? {
        var children: [any ASTNode] = []
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
    }

    init(binaryOperator: PklBinaryOperator, leftSide: (any ASTNode)?, rightSide: (any ASTNode)?,
         range: ASTRange, importDepth: Int, document: Document)
    {
        self.range = range
        self.importDepth = importDepth
        self.document = document
        self.leftSide = leftSide
        self.rightSide = rightSide
        self.binaryOperator = binaryOperator
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
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
