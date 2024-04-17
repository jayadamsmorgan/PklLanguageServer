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

    private func getModuleNameAndDocCommentByModuleImport(importNode: PklModuleImport) async -> (String, String?) {
        let moduleDeclaration =  importNode.module?.children?.first(where: { $0 is PklModuleHeader }) as? PklModuleHeader
        var moduleName = moduleDeclaration?.moduleClause?.name?.value ??
        importNode.documentToImport?.uri.split(separator: "/").last?.description ?? ""
        moduleName = moduleName.replacingOccurrences(of: ".pkl", with: "")
        if moduleName.starts(with: "pkl.") {
            moduleName = moduleName.replacingOccurrences(of: "pkl.", with: "")
        }
        if let docComment = moduleDeclaration?.docComment?.text
                    .replacingOccurrences(of: "/// ", with: "")
                    .replacingOccurrences(of: "///", with: "") {
            return (moduleName, docComment)
        }
        if let docComment = moduleDeclaration?.moduleClause?.docComment?.text
                    .replacingOccurrences(of: "/// ", with: "")
                    .replacingOccurrences(of: "///", with: "") {
            return (moduleName, docComment)
        }
        return (moduleName, nil)
    }

    private func findContextNode(node: ASTNode, key: String) async -> ASTNode? {
        guard let children = node.children else {
            return nil
        }
        for node in children {
            if let node = node as? PklModuleImport {
                let (moduleName, _) = await getModuleNameAndDocCommentByModuleImport(importNode: node)
                if key == moduleName {
                    if let module = node.module {
                        return module
                    }
                }
            }
            if let node = node as? PklClassDeclaration {
                if let name = node.classIdentifier?.value, key == name {
                    return node.classNode
                }
            }
            if let node = node as? PklObjectProperty,
                let identifier = node.identifier?.value,
                let value = node.value as? PklObjectBody,
                key == identifier {
                return value
            }
            if let node = node as? PklClassProperty,
                let identifier = node.identifier?.value,
                node.value is PklObjectBody,
                key == identifier {
                return node.value
            }
        }
        return nil
    }

    public func provideWithContext(module: ASTNode, params: CompletionParams) async -> CompletionResponse {
        let cursorPos = params.position
        logger.debug("cursorPos: \(cursorPos)")
        guard let undefined = ASTHelper.getPositionContext(module: module, position: cursorPos, importDepth: module.importDepth) else {
            logger.debug("Unable to find undefined AST Node at position \(cursorPos) for providing context completions.")
            return await provideWithKeywords()
        }
        logger.debug("undefined range: \(undefined.range.positionRange)")

        var undefinedText = undefined.document.getTextInByteRange(undefined.range.byteRange)
        logger.debug("undefinedText: \(undefinedText)")
        let undefinedPosLower = undefined.range.positionRange.lowerBound
        let line = cursorPos.line - undefinedPosLower.line
        let character = cursorPos.character - undefinedPosLower.character - 1
        do {
            guard let dotRelativeIndex = try Document.findPosition(Position((line, character)), in: undefinedText) else {
                logger.debug("Cannot provide completions with context: dotRelativeIndex is nil.")
                return await provideWithKeywords()
            }
            undefinedText = undefinedText[undefinedText.startIndex..<dotRelativeIndex].description
            logger.debug("Filtered undefinedText: \(undefinedText)")
        } catch {
            logger.error("Cannot provide completions with context: \(error)")
            return await provideWithKeywords()
        }

        var keys = undefinedText.split(separator: ".")
        keys = keys.map { key in
            return key.replacingOccurrences(of: "\n", with: " ").split(separator: " ").last ?? ""
        }
        logger.debug("Keys: \(keys)")
        guard let firstKey = keys.first?.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "\n", with: "") else {
            logger.debug("Cannot provide completions with context: firstKey is not present.")
            return await provideWithKeywords()
        }
        guard var context: ASTNode = await findContextNode(node: module, key: firstKey) else {
            logger.debug("Cannot provide completions with context: first context is nil.")
            return await provideWithKeywords()
        }
        for x in 0..<keys.count {
            if x == 0 {
                continue
            }
            let key = keys[x].replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "\n", with: "")
            let newContext = await findContextNode(node: context, key: key)
            guard let newContext else {
                return await provideWithKeywords()
            }
            context = newContext
        }
        return await provide(module: context)
    }

    public func provide(module: ASTNode, params: CompletionParams? = nil, keywords: Bool = true) async -> CompletionResponse {

        if let params {
            if params.context?.triggerKind == .triggerCharacter && params.context?.triggerCharacter == "." {
                return await provideWithContext(module: module, params: params)
            }
        }

        var completions: [CompletionItem] = []

        guard let children = module.children else {
            if keywords {
                return await provideWithKeywords(completions: completions)
            }
            return CompletionResponse(.optionB(CompletionList(isIncomplete: false, items: completions)))
        }

        for node in children {
            if let moduleHeader = node as? PklModuleHeader,
                let module = moduleHeader.extendsOrAmends?.module {
                let response = await provide(module: module)
                if let items = response?.items, items.count > 0 {
                    completions.append(contentsOf: items)
                }
            }
            if let importNode = node as? PklModuleImport {
                let (moduleName, docComment) = await getModuleNameAndDocCommentByModuleImport(importNode: importNode)
                if let docComment {
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

    private func standardFunctionsForStandardTypeNode(type: PklType) async -> [CompletionItem] {
        guard let identifier = type.identifier else {
            return []
        }
        if identifier == "Int" {
            return [
                CompletionItem(
                    label: "",
                    kind: .function,
                    detail: ""
                ),
            ]
        }
        if identifier == "String" {
            return [
                CompletionItem(
                    label: "",
                    kind: .function,
                    detail: ""
                ),
            ]
        }
        if identifier == "List" {
            return [
                CompletionItem(
                    label: "",
                    kind: .function,
                    detail: ""
                ),
            ]
        }
        if identifier == "Map" {
            return [
                CompletionItem(
                    label: "",
                    kind: .function,
                    detail: ""
                ),
            ]
        }
        return []
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
