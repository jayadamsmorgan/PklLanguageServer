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
            if let classObject = node as? PklClassDeclaration {
                let detail = classObject.classIdentifier?.value
                let label = classObject.classIdentifier?.value ?? ""
                if let docComment = classObject.docComment?.text
                    .replacingOccurrences(of: "/// ", with: "")
                    .replacingOccurrences(of: "///", with: "")
                {
                    completions.append(CompletionItem(
                        label: label,
                        kind: .class,
                        detail: detail,
                        documentation: .optionA(docComment)
                    ))
                    return
                }
                completions.append(CompletionItem(
                    label: label,
                    kind: .class,
                    detail: detail
                ))
                return
            }
            if let function = node as? PklFunctionDeclaration {
                let ident = function.body?.identifier?.value ?? ""
                var label = ident
                let detail = function.body?.typeAnnotation?.type?.identifier
                if let argsByteRange = function.body?.params?.range.byteRange {
                    label += function.document.getTextInByteRange(argsByteRange)
                }
                if let docComment = node.docComment?.text
                    .replacingOccurrences(of: "/// ", with: "")
                    .replacingOccurrences(of: "///", with: "")
                {
                    completions.append(CompletionItem(
                        label: label,
                        kind: .function,
                        detail: detail,
                        documentation: .optionA(docComment),
                        insertText: ident
                    ))
                    return
                }
                completions.append(CompletionItem(
                    label: label,
                    kind: .function,
                    detail: detail,
                    insertText: ident
                ))
                return
            }
            if let object = node as? PklObjectProperty {
                let detail = object.typeAnnotation?.type?.identifier
                if let docComment = object.docComment?.text
                    .replacingOccurrences(of: "/// ", with: "")
                    .replacingOccurrences(of: "///", with: "")
                {
                    completions.append(CompletionItem(
                        label: object.identifier?.value ?? "",
                        kind: .property,
                        detail: detail,
                        documentation: .optionA(docComment)
                    ))
                    return
                }
                completions.append(CompletionItem(
                    label: object.identifier?.value ?? "",
                    kind: .property,
                    detail: detail
                ))
                return
            }
            if let objectEntry = node as? PklObjectEntry {
                if let docComment = objectEntry.docComment?.text
                    .replacingOccurrences(of: "/// ", with: "")
                    .replacingOccurrences(of: "///", with: "")
                {
                    completions.append(CompletionItem(
                        label: objectEntry.strIdentifier?.value ?? "",
                        kind: .property,
                        documentation: .optionA(docComment)
                    ))
                    return
                }
                completions.append(CompletionItem(
                    label: objectEntry.strIdentifier?.value ?? "",
                    kind: .property
                ))
                return
            }
            if let classProperty = node as? PklClassProperty {
                var detail: String?
                if let typeIdent = classProperty.typeAnnotation?.type?.identifier {
                    detail = typeIdent
                }
                if let docComment = classProperty.docComment?.text
                    .replacingOccurrences(of: "/// ", with: "")
                    .replacingOccurrences(of: "///", with: "")
                {
                    completions.append(CompletionItem(
                        label: classProperty.identifier?.value ?? "",
                        kind: .property,
                        detail: detail,
                        documentation: .optionA(docComment)
                    ))
                    return
                }
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
                kind: .keyword
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
