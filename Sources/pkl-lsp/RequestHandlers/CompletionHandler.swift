import Foundation
import LanguageServerProtocol
import Logging


public class CompletionHandler {

    public let logger: Logger

    public init(logger: Logger) {
        self.logger = logger
    }

    private func iterate(node: any ASTNode) -> [CompletionItem] {
        var completions: [CompletionItem] = []
        if let object = node as? PklClassDeclaration {
            completions.append(CompletionItem(
                label: object.classIdentifier?.value ?? "",
                kind: .class,
                detail: "Pickle object"
            ))
        }
        if let function = node as? PklFunctionDeclaration {
            completions.append(CompletionItem(
                label: function.body?.identifier?.value ?? "",
                kind: .function,
                detail: "Pickle function"
            ))
        }
        return completions
    }

    private func getPositionContext(module: any ASTNode, position: Position) -> (any ASTNode)? {
        for node in module.children ?? [] {
            if node.positionStart.line <= position.line
                && node.positionEnd.line >= position.line
                && node.positionStart.character <= position.character
                && node.positionEnd.character >= position.character {
                if let context = getPositionContext(module: node, position: position) {
                    return context
                }
                return node
            }
        }
        return nil
    }

    public func provide(document: Document, module: any ASTNode, params: CompletionParams) async -> CompletionResponse {
        let positionContext = getPositionContext(module: module, position: params.position)
        if positionContext != nil && params.context?.triggerCharacter == "." {
            let completions = iterate(node: positionContext!)
            return CompletionResponse(.optionB(CompletionList(isIncomplete: false, items: completions)))
        }
        let keywordCompletions: [CompletionItem] = PklKeywords.allCases.map { keyword in
            CompletionItem(
                label: keyword.rawValue,
                kind: .keyword,
                detail: "Pickle keyword"
            )
        }
        let objectCompletions: [CompletionItem] = module.children?.compactMap { node in
            if let object = node as? PklClassDeclaration {
                return CompletionItem(
                    label: object.classIdentifier?.value ?? "",
                    kind: .class,
                    detail: "Pickle object"
                )
            }
            return nil
        } ?? []
        let functionCompletions: [CompletionItem] = module.children?.compactMap { node in
            if let function = node as? PklFunctionDeclaration {
                return CompletionItem(
                    label: function.body?.identifier?.value ?? "",
                    kind: .function,
                    detail: "Pickle function"
                )
            }
            return nil
        } ?? []
        let completions = keywordCompletions + objectCompletions + functionCompletions
        return CompletionResponse(.optionB(CompletionList(isIncomplete: false, items: completions)))
    }
}

enum PklKeywords : String, CaseIterable {
    case abstract
    case amends
    case `as`
    case `class`
    case `else`
    case extends
    case external
    case `false`
    case `for`
    case function
    case hidden
    case `if`
    case `import`
    case importStar = "import*"
    case `in`
    case `is`
    case `let`
    case local
    case module
    case new
    case nothing
    case null
    case open
    case out
    case outer
    case `super`
    case this
    case `throw`
    case trace
    case `true`
    case `typealias`
    case when
}

