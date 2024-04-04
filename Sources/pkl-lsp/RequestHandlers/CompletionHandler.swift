import Foundation
import LanguageServerProtocol
import Logging

public class CompletionHandler {
    public let logger: Logger

    public init(logger: Logger) {
        self.logger = logger
    }

    public func provide(module: ASTNode, params _: CompletionParams) async -> CompletionResponse {
        var completions: [CompletionItem] = []

        ASTHelper.enumerate(node: module) { node in
            var moduleName: String?
            if node.importDepth != 0 {
                moduleName = node.document.uri
                if moduleName != nil, moduleName!.starts(with: "file:///") {
                    moduleName = "\(moduleName!.split(separator: "/").last!)"
                }
            }
            var detail = ""
            if let moduleName {
                detail = "From \(moduleName):\n\n"
            }
            if let classObject = node as? PklClassDeclaration {
                detail += node.docComment?.text ?? "Pkl object"
                completions.append(CompletionItem(
                    label: classObject.classIdentifier?.value ?? "",
                    kind: .class,
                    detail: detail
                ))
                return
            }
            if let function = node as? PklFunctionDeclaration {
                detail += node.docComment?.text ?? "Pkl function"
                completions.append(CompletionItem(
                    label: function.body?.identifier?.value ?? "",
                    kind: .function,
                    detail: detail
                ))
                return
            }
            if let object = node as? PklObjectProperty {
                detail += node.docComment?.text ?? "Pkl object property"
                completions.append(CompletionItem(
                    label: object.identifier?.value ?? "",
                    kind: .property,
                    detail: detail
                ))
                return
            }
            if let objectEntry = node as? PklObjectEntry {
                detail += node.docComment?.text ?? "Pkl object entry"
                completions.append(CompletionItem(
                    label: objectEntry.strIdentifier?.value ?? "",
                    kind: .property,
                    detail: detail
                ))
                return
            }
            if let classProperty = node as? PklClassProperty {
                detail += node.docComment?.text ?? "Pkl property"
                completions.append(CompletionItem(
                    label: classProperty.identifier?.value ?? "",
                    kind: .property,
                    detail: detail
                ))
                return
            }
        }
        completions.append(contentsOf: PklKeywords.allCases.map { keyword in
            CompletionItem(
                label: keyword.rawValue,
                kind: .keyword,
                detail: "Pkl keyword"
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
