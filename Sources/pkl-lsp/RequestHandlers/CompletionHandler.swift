import Foundation
import LanguageServerProtocol
import Logging

public class CompletionHandler {
    public let logger: Logger

    public init(logger: Logger) {
        self.logger = logger
    }

    public func provide(document _: Document, module: ASTNode, params _: CompletionParams) async -> CompletionResponse {
        var completions: [CompletionItem] = []

        ASTHelper.enumerate(node: module) { node in
            if let classObject = node as? PklClassDeclaration {
                completions.append(CompletionItem(
                    label: classObject.classIdentifier?.value ?? "",
                    kind: .class,
                    detail: "Pickle object"
                ))
                return
            }
            if let function = node as? PklFunctionDeclaration {
                completions.append(CompletionItem(
                    label: function.body?.identifier?.value ?? "",
                    kind: .function,
                    detail: "Pickle function"
                ))
                return
            }
            if let object = node as? PklObjectProperty {
                completions.append(CompletionItem(
                    label: object.identifier?.value ?? "",
                    kind: .property,
                    detail: "Pickle object property"
                ))
                return
            }
            if let objectEntry = node as? PklObjectEntry {
                completions.append(CompletionItem(
                    label: objectEntry.strIdentifier?.value ?? "",
                    kind: .property,
                    detail: "Pickle object entry"
                ))
                return
            }
            if let classProperty = node as? PklClassProperty {
                completions.append(CompletionItem(
                    label: classProperty.identifier?.value ?? "",
                    kind: .property,
                    detail: "Pickle property"
                ))
                return
            }
        }
        completions.append(contentsOf: PklKeywords.allCases.map { keyword in
            CompletionItem(
                label: keyword.rawValue,
                kind: .keyword,
                detail: "Pickle keyword"
            )
        })
        // Remove duplicates from completions
        completions = completions.reduce(into: [CompletionItem]()) { result, completion in
            if !result.contains(completion) {
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
