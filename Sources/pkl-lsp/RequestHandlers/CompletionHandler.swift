import Foundation
import LanguageServerProtocol
import Logging

public class CompletionHandler {
    public let logger: Logger

    public init(logger: Logger) {
        self.logger = logger
    }

    public func provideWithKeywords(completions: [CompletionItem] = []) async -> CompletionResponse {
        var completions = completions
        completions.append(contentsOf: PklKeywords.allCases.map { keyword in
            CompletionItem(
                label: keyword.rawValue,
                kind: .keyword
            )
        })
        return CompletionResponse(.optionB(CompletionList(isIncomplete: false, items: completions)))
    }

    public func provide(module: ASTNode, params: CompletionParams, keywords: Bool = true) async -> CompletionResponse {
        var completions: [CompletionItem] = []

        guard let children = module.children else {
            if keywords {
                return await provideWithKeywords(completions: completions)
            }
            return CompletionResponse(.optionB(CompletionList(isIncomplete: false, items: completions)))
        }

        for node in children {
            if let importNode = node as? PklModuleImport {
                let moduleDeclaration =  importNode.module?.children?.first(where: { $0 is PklModuleHeader }) as? PklModuleHeader
                var moduleName = moduleDeclaration?.moduleClause?.name?.value ??
                    importNode.documentToImport?.uri.split(separator: "/").last?.description ?? ""
                moduleName = moduleName.replacingOccurrences(of: ".pkl", with: "")
                if moduleName.starts(with: "pkl.") {
                    moduleName = moduleName.replacingOccurrences(of: "pkl.", with: "")
                }
                if let docComment = moduleDeclaration?.docComment?.text
                    .replacingOccurrences(of: "/// ", with: "")
                    .replacingOccurrences(of: "///", with: "")
                {
                    completions.append(CompletionItem(
                        label: moduleName,
                        kind: .module,
                        detail: moduleName,
                        documentation: .optionA(docComment)
                    ))
                    continue
                }
                if let docComment = moduleDeclaration?.moduleClause?.docComment?.text
                    .replacingOccurrences(of: "/// ", with: "")
                    .replacingOccurrences(of: "///", with: "")
                {
                    completions.append(CompletionItem(
                        label: moduleName,
                        kind: .module,
                        detail: moduleName,
                        documentation: .optionA(docComment)
                    ))
                    continue
                }
                completions.append(CompletionItem(
                    label: moduleName,
                    kind: .module,
                    detail: moduleName
                ))
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
                    continue
                }
                completions.append(CompletionItem(
                    label: label,
                    kind: .class,
                    detail: detail
                ))
                continue
            }
            if let function = node as? PklFunctionDeclaration {
                if let body = function.body, body.isLocal && function.importDepth > 0 {
                    continue
                }
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
                    continue
                }
                completions.append(CompletionItem(
                    label: label,
                    kind: .function,
                    detail: detail,
                    insertText: ident
                ))
                continue
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
                    continue
                }
                completions.append(CompletionItem(
                    label: object.identifier?.value ?? "",
                    kind: .property,
                    detail: detail
                ))
                continue
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
                    continue
                }
                completions.append(CompletionItem(
                    label: objectEntry.strIdentifier?.value ?? "",
                    kind: .property
                ))
                continue
            }
            if let classProperty = node as? PklClassProperty {
                if classProperty.isLocal && classProperty.importDepth > 0 {
                    continue
                }
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
                    continue
                }
                completions.append(CompletionItem(
                    label: classProperty.identifier?.value ?? "",
                    kind: .property,
                    detail: detail
                ))
                continue
            }
        }
        // Remove duplicates from completions
        completions = completions.reduce(into: [CompletionItem]()) { result, completion in
            if !result.contains(completion) {
                result.append(completion)
            }
        }
        if keywords {
            return await provideWithKeywords(completions: completions)
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
