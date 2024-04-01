import Foundation
import LanguageServerProtocol
import Logging

public class DocumentSymbolsHandler {
    public let logger: Logger

    public init(logger: Logger) {
        self.logger = logger
    }

    private func getSymbols(node: ASTNode) async -> [DocumentSymbol] {
        guard let children = node.children else {
            return []
        }
        var symbols: [DocumentSymbol] = []
        for child in children {
            if let objectBody = child as? PklObjectBody {
                symbols.append(contentsOf: await getSymbols(node: objectBody))
            }
            if let classNode = child as? PklClassDeclaration {
                symbols.append(await createDocumentSymbol(node: classNode, name: classNode.classIdentifier?.value, kind: .class))
            }
            if let functionNode = child as? PklFunctionDeclaration {
                symbols.append(await createDocumentSymbol(node: functionNode, name: functionNode.body?.identifier?.value, kind: .function))
            }
            if let propertyNode = child as? PklObjectProperty {
                symbols.append(await createDocumentSymbol(node: propertyNode, name: propertyNode.identifier?.value, kind: .property))
            }
            if let propertyNode = child as? PklClassProperty {
                symbols.append(await createDocumentSymbol(node: propertyNode, name: propertyNode.identifier?.value, kind: .property))
            }
        }
        return symbols
    }

    private func createDocumentSymbol<T: ASTNode>(node: T, name: String?, kind: SymbolKind) async -> DocumentSymbol {
        DocumentSymbol(
            name: name ?? "Unknown",
            detail: name ?? "Unknown",
            kind: kind,
            range: node.range.getLSPRange(),
            selectionRange: node.range.getLSPRange(),
            children: await getSymbols(node: node)
        )
    }

    public func provide(document _: Document, module: ASTNode, params: DocumentSymbolParams) async -> DocumentSymbolResponse {
        if let moduleHeader = module.children?.first(where: { $0 is PklModuleHeader }) as? PklModuleHeader {
            let symbols = DocumentSymbol(
                name: moduleHeader.moduleClause?.name?.value ?? "Module",
                detail: moduleHeader.moduleClause?.name?.value ?? "Module",
                kind: .module,
                range: module.range.getLSPRange(),
                selectionRange: module.range.getLSPRange(),
                children: await getSymbols(node: module)
            )
            return DocumentSymbolResponse(.optionA([symbols]))
        }
        let symbols: [DocumentSymbol] = await getSymbols(node: module)
        logger.debug("LSP DocumentSymbols: Found \(symbols.count) symbols in \(params.textDocument.uri).")
        return DocumentSymbolResponse(.optionA(symbols))
    }
}
