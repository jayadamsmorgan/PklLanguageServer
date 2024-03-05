import Foundation
import LanguageServerProtocol
import Logging

public class DocumentSymbolsHandler {
    public let logger: Logger

    public init(logger: Logger) {
        self.logger = logger
    }

    private func getSymbols(node: any ASTNode) -> [DocumentSymbol] {
        guard let children = node.children else {
            return []
        }
        var symbols: [DocumentSymbol] = []
        for child in children {
            if let classNode = child as? PklClassDeclaration {
                let classSymbol = DocumentSymbol(
                    name: classNode.classIdentifier?.value ?? "Unknown",
                    detail: "class",
                    kind: .class,
                    range: classNode.range.getLSPRange(),
                    selectionRange: classNode.range.getLSPRange(),
                    children: getSymbols(node: classNode)
                )
                symbols.append(classSymbol)
            }
            if let functionNode = child as? PklFunctionDeclaration {
                let functionSymbol = DocumentSymbol(
                    name: functionNode.body?.identifier?.value ?? "Unknown",
                    detail: "function",
                    kind: .function,
                    range: functionNode.range.getLSPRange(),
                    selectionRange: functionNode.range.getLSPRange(),
                    children: getSymbols(node: functionNode)
                )
                symbols.append(functionSymbol)
            }
            if let objectNode = child as? PklObjectBody {
                let objectSymbol = DocumentSymbol(
                    name: "Object",
                    detail: "object",
                    kind: .module,
                    range: objectNode.range.getLSPRange(),
                    selectionRange: objectNode.range.getLSPRange(),
                    children: getSymbols(node: objectNode)
                )
                symbols.append(objectSymbol)
            }
            if let propertyNode = child as? PklObjectProperty {
                let propertySymbol = DocumentSymbol(
                    name: propertyNode.identifier?.value ?? "Unknown",
                    detail: "property",
                    kind: .property,
                    range: propertyNode.range.getLSPRange(),
                    selectionRange: propertyNode.range.getLSPRange(),
                    children: getSymbols(node: propertyNode)
                )
                symbols.append(propertySymbol)
            }
            if let propertyNode = child as? PklClassProperty {
                let propertySymbol = DocumentSymbol(
                    name: propertyNode.identifier?.value ?? "Unknown",
                    detail: "property",
                    kind: .property,
                    range: propertyNode.range.getLSPRange(),
                    selectionRange: propertyNode.range.getLSPRange(),
                    children: getSymbols(node: propertyNode)
                )
                symbols.append(propertySymbol)
            }
        }
        return symbols
    }

    public func provide(document _: Document, module: any ASTNode, params: DocumentSymbolParams) async -> DocumentSymbolResponse {
        let symbols: [DocumentSymbol] = getSymbols(node: module)
        logger.debug("LSP DocumentSymbols: Found \(symbols.count) symbols in \(params.textDocument.uri).")
        return DocumentSymbolResponse(.optionA(symbols))
    }
}
