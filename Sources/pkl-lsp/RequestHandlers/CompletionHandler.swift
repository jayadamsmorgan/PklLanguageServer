import Foundation
import LanguageServerProtocol
import Logging

public class CompletionHandler {
    public let logger: Logger

    public init(logger: Logger) {
        self.logger = logger
    }

    public func provide(document _: Document, module: any ASTNode, params: CompletionParams) async -> CompletionResponse {
        //let positionContext = ASTHelper.getPositionContext(module: module, position: params.position)
        var completions: [CompletionItem] = []
        ASTHelper.enumerate(node: module) { node in
            if let function = node as? PklFunctionDeclaration {
                completions.append(CompletionItem(
                    label: function.body?.identifier?.value ?? "",
                    kind: .function,
                    detail: "Pickle function"
                ))
            }
            if let classDeclaration = node as? PklClassDeclaration {
                completions.append(CompletionItem(
                    label: classDeclaration.classIdentifier?.value ?? "",
                    kind: .class,
                    detail: "Pickle object"
                ))
            }
            if let property = node as? PklClassProperty {
                completions.append(CompletionItem(
                    label: property.identifier?.value ?? "",
                    kind: .property,
                    detail: "Pickle property"
                ))
            }
            if let object = node as? PklObjectProperty {
                completions.append(CompletionItem(
                    label: object.identifier?.value ?? "",
                    kind: .class,
                    detail: "Pickle object property"
                ))
            }
            if let objectEntry = node as? PklObjectEntry {
                completions.append(CompletionItem(
                    label: objectEntry.strIdentifier?.value ?? "",
                    kind: .class,
                    detail: "Pickle object entry"
                ))
            }
        }

        let keywordCompletions: [CompletionItem] = PklKeywords.allCases.map { keyword in
            CompletionItem(
                label: keyword.rawValue,
                kind: .keyword,
                detail: "Pickle keyword"
            )
        }
        completions.append(contentsOf: keywordCompletions)

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
        completions.append(contentsOf: objectCompletions)

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
        completions.append(contentsOf: functionCompletions)

        completions = completions.reduce(into: [CompletionItem]()) { result, completion in
            if !result.contains(where: { $0.label == completion.label && $0.kind == completion.kind  && $0.detail == completion.detail }) {
                result.append(completion)
            }
        }

        return CompletionResponse(.optionB(CompletionList(isIncomplete: false, items: completions)))
    }
}

enum PklKeywords: String, CaseIterable {
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
