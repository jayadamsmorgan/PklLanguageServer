import Foundation
import LanguageServerProtocol

enum PklNumberType {
    case int
    case uint
    case float
    case int8
    case int16
    case int32
    case uint8
    case uint16
    case uint32
}

struct PklNumberLiteral: ASTNode {
    let uniqueID: UUID = .init()

    var range: ASTRange
    let importDepth: Int

    var value: String?
    var type: PklNumberType

    var children: [any ASTNode]? = nil

    init(value: String? = nil, type: PklNumberType, range: ASTRange, importDepth: Int) {
        self.value = value
        self.type = type
        self.range = range
        self.importDepth = importDepth
    }

    public func diagnosticErrors() -> [ASTDiagnosticError]? {
        if value != nil {
            return nil
        }
        return [ASTDiagnosticError("Provide number value", .error, range)]
    }
}
