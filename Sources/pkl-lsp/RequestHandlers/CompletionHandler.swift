import Foundation
import LanguageServerProtocol
import Logging

public class CompletionHandler {
    public let logger: Logger

    public init(logger: Logger) {
        self.logger = logger
    }

    private func provideWithKeywords(completions: [CompletionItem] = []) async -> CompletionResponse {
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
            .replacingOccurrences(of: "pkl.", with: "")
            .replacingOccurrences(of: "stdlib:", with: "")
        if let docComment = docCommentForNode(node: moduleDeclaration) {
            return (moduleName, docComment)
        }
        if let docComment = docCommentForNode(node: moduleDeclaration?.moduleClause) {
            return (moduleName, docComment)
        }
        return (moduleName, nil)
    }

    private func findContextNode(node: ASTNode, key: String) async -> ASTNode? {
        guard var children = node.children else {
            return nil
        }
        var module: PklModule? = node as? PklModule
        while module != nil {
            guard let moduleHeader = module?.children?.first(where: { $0 is PklModuleHeader }) as? PklModuleHeader,
                    let extendsOrAmends = moduleHeader.extendsOrAmends else {
                break
            }
            if let extended = extendsOrAmends.module {
                children.append(contentsOf: extended.children ?? [])
                module = extended
                logger.error("\(extended.document.uri)")
                continue
            }
            break
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
                key == identifier {
                if node.value is PklObjectBody {
                    return node.value
                }
                return node
            }
        }
        return nil
    }

    private func docCommentForNode(node: ASTNode?) -> String? {
        guard let node = node else {
            return nil
        }
        if let docComment = node.docComment?.text
            .replacingOccurrences(of: "/// ", with: "")
            .replacingOccurrences(of: "///", with: "") {
            return docComment
        }
        return nil
    }

    public func provideWithContext(module: ASTNode, params: CompletionParams) async -> CompletionResponse {
        var cursorPos = Position.zero
        if params.position.character >= 2 {
            cursorPos = Position((params.position.line, params.position.character - 2))
        } else {
            cursorPos = params.position
        }
        logger.debug("cursorPos: \(cursorPos)")
        guard let undefined = ASTHelper.getPositionContext(module: module, position: cursorPos, importDepth: module.importDepth) else {
            logger.debug("Unable to find undefined AST Node at position \(cursorPos) for providing context completions.")
            return nil
        }
        cursorPos = params.position
        logger.debug("undefined range: \(undefined.range.positionRange)")

        var undefinedText = undefined.document.getTextInByteRange(undefined.range.byteRange)
        logger.debug("undefinedText: \(undefinedText)")
        let undefinedPosLower = undefined.range.positionRange.lowerBound
        let line = cursorPos.line - undefinedPosLower.line
        let character = cursorPos.character - undefinedPosLower.character - 1
        do {
            guard let dotRelativeIndex = try Document.findPosition(Position((line, character)), in: undefinedText) else {
                logger.debug("Cannot provide completions with context: dotRelativeIndex is nil.")
                return nil
            }
            undefinedText = undefinedText[undefinedText.startIndex..<dotRelativeIndex].description
            logger.debug("Filtered undefinedText: \(undefinedText)")
        } catch {
            logger.error("Cannot provide completions with context: \(error)")
            return nil
        }

        guard let lastChar = undefinedText.last else {
            logger.error("Cannot provide completions with context: lastChar is nil.")
            return nil
        }

        if lastChar == "\"" {
            // String literal (probably)
            let completions = await provideStandardFunctionsForStandardTypeNode(type: "String")
            return .optionB(CompletionList(isIncomplete: false, items: completions))
        }

        var keys = undefinedText.split(separator: ".")
        keys = keys.map { key in
            return key.replacingOccurrences(of: "\n", with: " ").split(separator: " ").last ?? ""
        }
        logger.debug("Keys: \(keys)")
        guard let firstKey = keys.first?.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "\n", with: "") else {
            logger.debug("Cannot provide completions with context: firstKey is not present.")
            return nil
        }
        guard var context: ASTNode = await findContextNode(node: module, key: firstKey) else {
            logger.debug("Cannot provide completions with context: first context is nil.")
            return nil
        }
        for x in 0..<keys.count {
            if x == 0 {
                continue
            }
            let key = keys[x].replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "\n", with: "")
            let newContext = await findContextNode(node: context, key: key)
            guard let newContext else {
                return nil
            }
            context = newContext
        }
        return await provide(module: context)
    }

    public func provide(module: ASTNode, params: CompletionParams? = nil) async -> CompletionResponse {

        if let params {
            if params.context?.triggerKind == .triggerCharacter && params.context?.triggerCharacter == "." {
                return await provideWithContext(module: module, params: params)
            }
        }

        var completions: [CompletionItem] = []

        guard let children = module.children else {
            if module is PklModule && module.importDepth == 0 {
                completions = await provideStandardFunctionsForStandardTypeNode(type: "Module")
                return await provideWithKeywords(completions: completions)
            }
            return await provideWithKeywords()
        }

        if let property = module as? PklClassProperty, !(property.value is PklObjectBody) {
            completions = await provideStandardFunctionsForStandardTypeNode(type: property.typeAnnotation?.type?.identifier ?? "")
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
                if let docComment = docCommentForNode(node: classObject) {
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
                if let docComment = docCommentForNode(node: node) {
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
                if let docComment = docCommentForNode(node: object) {
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
                if let docComment = docCommentForNode(node: objectEntry) {
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
                if let docComment = docCommentForNode(node: classProperty) {
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
        if module is PklModule && module.importDepth == 0 {
            completions.append(contentsOf: await provideStandardFunctionsForStandardTypeNode(type: "Module"))
            return await provideWithKeywords(completions: completions)
        }
        return .optionB(CompletionList(isIncomplete: false, items: completions))
    }

    private func provideStandardFunctionsForStandardTypeNode(type identifier: String) async -> [CompletionItem] {
        if identifier == "Module" {
            let completions = [
                CompletionItem(
                    label: "isBetween(x: Number, y: Number)",
                    kind: .function,
                    detail: "Number",
                    insertText: "isBetween()"
                ),
                
                // Properties
                CompletionItem(
                    label: "NaN",
                    kind: .property,
                    detail: "Float",
                    documentation: .optionA("The Float value that is not a number (NaN).")
                ),
                CompletionItem(
                    label: "Infinity",
                    kind: .property,
                    detail: "Float",
                    documentation: .optionA("The Float value that is positive Infinity. For negative infinity, use -Infinity.")
                ),

                // Methods
                CompletionItem(
                    label: "Regex(pattern: String)",
                    kind: .function,
                    detail: "Regex",
                    documentation: .optionA("""
                    Constructs a regular expression described by pattern.

                    Throws if pattern is not a valid regular expression.

                    To test if pattern is a valid regular expression, use String.isRegex.
                    """),
                    insertText: "Regex()"
                ),
                CompletionItem(
                    label: "Undefined()",
                    kind: .function,
                    detail: "nothing",
                    documentation: .optionA("Throws an error indicating that the requested value is undefined."),
                    insertText: "Undefined()"
                ),
                CompletionItem(
                    label: "TODO()",
                    kind: .function,
                    detail: "nothing",
                    documentation: .optionA("Throws an error indicating that the requested functionality has not yet been implemented."),
                    insertText: "TODO()"
                ),
                CompletionItem(
                    label: "Null(defaultValue: Object|Function<Object>)",
                    kind: .function,
                    detail: "Null",
                    documentation: .optionA("Creates a null value that turns into defaultValue when amended."),
                    insertText: "Null()"
                ),
                CompletionItem(
                    label: "Pair<First, Second>(first: First, second: Second)",
                    kind: .function,
                    detail: "Pair<First, Second>",
                    documentation: .optionA("Constructs a Pair."),
                    insertText: "Pair<>()"
                ),
                CompletionItem(
                    label: "IntSeq(start: Int, end: Int)",
                    kind: .function,
                    detail: "IntSeq",
                    documentation: .optionA("""
                    Constructs an IntSeq with the given start, end, and step 1.

                    To set a step other than 1, use method IntSeq.step().
                    """),
                    insertText: "IntSeq()"
                ),
                CompletionItem(
                    label: "List<Element>(elements: VarArgs<Element>)",
                    kind: .function,
                    detail: "List<Element>",
                    documentation: .optionA("""
                    Creates a list containing the given elements.

                    This method accepts any number of arguments.
                    """),
                    insertText: "List<>()"
                ),
                CompletionItem(
                    label: "Set<Element>(elements: VarArgs<Element>)",
                    kind: .function,
                    detail: "Set<Element>",
                    documentation: .optionA("""
                    Creates a set containing the given elements.

                    This method accepts any number of arguments.
                    """),
                    insertText: "Set<>()"
                ),
                CompletionItem(
                    label: "Map<Key, Value>(keysAndValues: VarArgs<(Key|Value)>)",
                    kind: .function,
                    detail: "Map<Key, Value>",
                    documentation: .optionA("Creates a map containing the given alternating keysAndValues."),
                    insertText: "Map<>()"
                ),
                
                // Classes
                CompletionItem(
                    label: "Any",
                    kind: .class,
                    documentation: .optionA("The top type of the type hierarchy.")
                ),
                CompletionItem(
                    label: "Null",
                    kind: .class,
                    detail: "extends Any",
                    documentation: .optionA("The type of null and null values created with Null().")
                ),
                CompletionItem(
                    label: "Class<out Type>",
                    kind: .class,
                    detail: "extends Any",
                    documentation: .optionA("The runtime representation of a class.")
                ),
                CompletionItem(
                    label: "TypeAlias",
                    kind: .class,
                    detail: "extends Any",
                    documentation: .optionA("The runtime representation of a type alias.")
                ),
                CompletionItem(
                    label: "Module",
                    kind: .class,
                    documentation: .optionA("Base class for modules.")
                ),
                CompletionItem(
                    label: "Annotation",
                    kind: .class,
                    documentation: .optionA("Base class for annotation types.")
                ),
                CompletionItem(
                    label: "Since",
                    kind: .class,
                    detail: "extends Annotation",
                    documentation: .optionA("Indicates that the annotated member was introduced in version.")
                ),
                CompletionItem(
                    label: "Deprecated",
                    kind: .class,
                    detail: "extends Annotation",
                    documentation: .optionA("Indicates that the annotated member is deprecated and will likely be removed in the future.")
                ),
                CompletionItem(
                    label: "AlsoKnownAs",
                    kind: .class,
                    detail: "extends Annotation",
                    documentation: .optionA("Lists alternative names that the annotated member is known under.")
                ),
                CompletionItem(
                    label: "Unlisted",
                    kind: .class,
                    detail: "extends Annotation",
                    documentation: .optionA("Indicates that the annotated member should not be advertised by Pkldoc and other tools.")
                ),
                CompletionItem(
                    label: "DocExample",
                    kind: .class,
                    detail: "extends Annotation",
                    documentation: .optionA("Indicates to Pkldoc that the annotated module is an example for how to use subjects.")
                ),
                CompletionItem(
                    label: "SourceCode",
                    kind: .class,
                    detail: "extends Annotation",
                    documentation: .optionA("Indicates that the annotated property's string value contains source code written in language.")
                ),
                CompletionItem(
                    label: "ModuleInfo",
                    kind: .class,
                    detail: "extends Annotation",
                    documentation: .optionA("Metadata for a module.")
                ),
                CompletionItem(
                    label: "FileOutput",
                    kind: .class,
                    documentation: .optionA("A representation of a rendered output.")
                ),
                CompletionItem(
                    label: "ModuleOutput",
                    kind: .class,
                    detail: "extends FileOutput",
                    documentation: .optionA("The contents and appearance of a module's output.")
                ),
                CompletionItem(
                    label: "ValueRenderer",
                    kind: .class,
                    documentation: .optionA("Base class for rendering Pkl values in some output format.")
                ),
                CompletionItem(
                    label: "PcfRenderer",
                    kind: .class,
                    detail: "extends ValueRenderer",
                    documentation: .optionA("Renders values as Pcf, a static subset of Pkl.")
                ),
                CompletionItem(
                    label: "RenderDirective",
                    kind: .class,
                    documentation: .optionA("Directs a ValueRenderer to output text as-is in place of this directive.")
                ),
                CompletionItem(
                    label: "PcfRenderDirective",
                    kind: .class,
                    documentation: .optionA("Directs PcfRenderer to output additional text before and/or after rendering a value.")
                ),
                CompletionItem(
                    label: "JsonRenderer",
                    kind: .class,
                    detail: "extends ValueRenderer",
                    documentation: .optionA("Renders values as JSON.")
                ),
                CompletionItem(
                    label: "YamlRenderer",
                    kind: .class,
                    detail: "extends ValueRenderer",
                    documentation: .optionA("Renders values as YAML.")
                ),
                CompletionItem(
                    label: "PListRenderer",
                    kind: .class,
                    detail: "extends ValueRenderer",
                    documentation: .optionA("Renders values as XML property lists.")
                ),
                CompletionItem(
                    label: "PropertiesRenderer",
                    kind: .class,
                    detail: "extends ValueRenderer",
                    documentation: .optionA("Renders values as Java Properties.")
                ),
                CompletionItem(
                    label: "Resource",
                    kind: .class,
                    documentation: .optionA("An external (file, HTTP, etc.) resource.")
                ),
                CompletionItem(
                    label: "Number",
                    kind: .class,
                    detail: "extends Any",
                    documentation: .optionA("Common base class of Int and Float.")
                ),
                CompletionItem(
                    label: "Int",
                    kind: .class,
                    detail: "extends Number",
                    documentation: .optionA("A 64-bit signed integer.")
                ),
                CompletionItem(
                    label: "Float",
                    kind: .class,
                    detail: "extends Number",
                    documentation: .optionA("A 64-bit floating-point number conforming to the IEEE 754 binary64 format.")
                ),
                CompletionItem(
                    label: "Boolean",
                    kind: .class,
                    detail: "extends Any",
                    documentation: .optionA("A boolean value, either true or false.")
                ),
                CompletionItem(
                    label: "String",
                    kind: .class,
                    detail: "extends Any",
                    documentation: .optionA("A sequence of Unicode characters (code points).")
                ),
                CompletionItem(
                    label: "Regex",
                    kind: .class,
                    documentation: .optionA("A regular expression to match strings against.")
                ),
                CompletionItem(
                    label: "RegexMatch",
                    kind: .class,
                    documentation: .optionA("A match of a regular expression in a string.")
                ),
                CompletionItem(
                    label: "Duration",
                    kind: .class,
                    detail: "extends Any",
                    documentation: .optionA("A quantity of elapsed time, represented as a value (e.g. 30.5) and unit (e.g. min).")
                ),
                CompletionItem(
                    label: "DataSize",
                    kind: .class,
                    detail: "extends Any",
                    documentation: .optionA("A quantity of binary data, represented as a value (e.g. 30.5) and unit (e.g. mb).")
                ),
                CompletionItem(
                    label: "Object",
                    kind: .class,
                    detail: "extends Any",
                    documentation: .optionA("A composite value containing members (properties, elements, entries).")
                ),
                CompletionItem(
                    label: "Typed",
                    kind: .class,
                    detail: "extends Object",
                    documentation: .optionA("Base class for objects whose members are described by a class definition.")
                ),
                CompletionItem(
                    label: "Dynamic",
                    kind: .class,
                    detail: "extends Object",
                    documentation: .optionA("An object that can contain arbitrary properties, elements, and entries.")
                ),
                CompletionItem(
                    label: "Listing<out Element>",
                    kind: .class,
                    detail: "extends Object",
                    documentation: .optionA("An object containing an ordered sequence of elements."),
                    insertText: "Listing<>"
                ),
                CompletionItem(
                    label: "Mapping<out Key, out Value>",
                    kind: .class,
                    detail: "extends Object",
                    documentation: .optionA("An object containing an ordered sequence of key-value pairs."),
                    insertText: "Mapping<>"
                ),
                CompletionItem(
                    label: "Function<out Result>",
                    kind: .class,
                    detail: "extends Any",
                    documentation: .optionA("Base class for function literals (also known as lambda expressions)."),
                    insertText: "Function<>"
                ),
                CompletionItem(
                    label: "Function0<out Result>",
                    kind: .class,
                    detail: "extends Function<Result>",
                    documentation: .optionA("A function literal with zero parameters."),
                    insertText: "Function0<>"
                ),
                CompletionItem(
                    label: "Function1<out Result>",
                    kind: .class,
                    detail: "extends Function<Result>",
                    documentation: .optionA("A function literal with one parameter."),
                    insertText: "Function1<>"
                ),
                CompletionItem(
                    label: "Function2<out Result>",
                    kind: .class,
                    detail: "extends Function<Result>",
                    documentation: .optionA("A function literal with two parameters."),
                    insertText: "Function2<>"
                ),
                CompletionItem(
                    label: "Function3<out Result>",
                    kind: .class,
                    detail: "extends Function<Result>",
                    documentation: .optionA("A function literal with three parameters."),
                    insertText: "Function3<>"
                ),
                CompletionItem(
                    label: "Function4<out Result>",
                    kind: .class,
                    detail: "extends Function<Result>",
                    documentation: .optionA("A function literal with four parameters."),
                    insertText: "Function4<>"
                ),
                CompletionItem(
                    label: "Function5<out Result>",
                    kind: .class,
                    detail: "extends Function<Result>",
                    documentation: .optionA("A function literal with five parameters."),
                    insertText: "Function5<>"
                ),
                CompletionItem(
                    label: "Pair<out First, out Second>",
                    kind: .class,
                    detail: "extends Any",
                    documentation: .optionA("An ordered pair of elements."),
                    insertText: "Pair<>"
                ),
                CompletionItem(
                    label: "Collection<out Element>",
                    kind: .class,
                    detail: "extends Any",
                    documentation: .optionA("Common base class for List and Set."),
                    insertText: "Collection<>"
                ),
                CompletionItem(
                    label: "IntSeq",
                    kind: .class,
                    detail: "extends Any",
                    documentation: .optionA("A finite arithmetic sequence of integers.")
                ),
                CompletionItem(
                    label: "VarArgs<Type>",
                    kind: .class,
                    detail: "extends Any",
                    documentation: .optionA("A variable number of method arguments of type Type."),
                    insertText: "VarArgs<>"
                ),
                CompletionItem(
                    label: "List<out Element>",
                    kind: .class,
                    detail: "extends Collection<Element>",
                    documentation: .optionA("An indexed sequence of elements."),
                    insertText: "List<>"
                ),
                CompletionItem(
                    label: "Set<out Element>",
                    kind: .class,
                    detail: "extends Collection<Element>",
                    documentation: .optionA("An unordered collection of unique elements."),
                    insertText: "Set<>"
                ),
                CompletionItem(
                    label: "Map<out Key, out Value>",
                    kind: .class,
                    detail: "extends Any",
                    documentation: .optionA("An unordered mapping from keys to values."),
                    insertText: "Map<>"
                ),

                // Type Aliases
                CompletionItem(
                    label: "NonNull",
                    kind: .typeParameter,
                    detail: "Any(!(this is Null))",
                    documentation: .optionA("A non-null value.")
                ),
                CompletionItem(
                    label: "Int8",
                    kind: .typeParameter,
                    detail: "Int(isBetween(-128, 127))",
                    documentation: .optionA("An Int value in range math.minInt8..math.maxInt8.")
                ),
                CompletionItem(
                    label: "Int16",
                    kind: .typeParameter,
                    detail: "Int(isBetween(-32768, 32767))",
                    documentation: .optionA("A non-null value.")
                ),
                CompletionItem(
                    label: "Int32",
                    kind: .typeParameter,
                    detail: "Int(isBetween(-2147483648, 2147483647))",
                    documentation: .optionA("An Int value in range math.minInt32..math.maxInt32.")
                ),
                CompletionItem(
                    label: "UInt8",
                    kind: .typeParameter,
                    detail: "Int(isBetween(0, 255))",
                    documentation: .optionA("An Int value in range 0..math.maxUInt8.")
                ),
                CompletionItem(
                    label: "UInt16",
                    kind: .typeParameter,
                    detail: "Int(isBetween(0, 65535))",
                    documentation: .optionA("An Int value in range 0..math.maxUInt16.")
                ),
                CompletionItem(
                    label: "UInt32",
                    kind: .typeParameter,
                    detail: "Int(isBetween(0, 4294967295))",
                    documentation: .optionA("An Int value in range 0..math.maxUInt32.")
                ),
                CompletionItem(
                    label: "UInt",
                    kind: .typeParameter,
                    detail: "Int(isPositive)",
                    documentation: .optionA("""
                    An Int value in range 0..math.maxUInt.

                    Note that math.maxUInt is equal to math.maxInt, not maxInt * 2 + 1 as one might expect. That is, UInt has half the range of Int.
                    """)
                ),
                CompletionItem(
                    label: "Comparable",
                    kind: .typeParameter,
                    detail: "String|Number|Duration|DataSize",
                    documentation: .optionA("A value that can be compared to another value of the same type with <, >, <=, and >=.")
                ),
                CompletionItem(
                    label: "Char",
                    kind: .typeParameter,
                    detail: "String(this.length == 1)",
                    documentation: .optionA("A Unicode character (code point).")
                ),
                CompletionItem(
                    label: "Uri",
                    kind: .typeParameter,
                    detail: "String",
                    documentation: .optionA("A string representing a URI.")
                ),
                CompletionItem(
                    label: "DurationUnit",
                    kind: .typeParameter,
                    detail: "\"ns\"|\"us\"|\"ms\"|\"s\"|\"min\"|\"h\"|\"d\"",
                    documentation: .optionA("The unit of a Duration.")
                ),
                CompletionItem(
                    label: "DataSizeUnit",
                    kind: .typeParameter,
                    detail: "\"b\"|\"kb\"|\"kib\"|\"mb\"|\"mib\"|\"gb\"|\"gib\"|\"tb\"|\"tib\"|\"pb\"|\"pib\"",
                    documentation: .optionA("The unit of a DataSize.")
                ),
                CompletionItem(
                    label: "Mixin<Type>",
                    kind: .typeParameter,
                    detail: "(Type) -> Type",
                    documentation: .optionA("An anonymous function used to apply the same modification to different objects.")
                ),
            ]
            return completions
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
                // Properties
                CompletionItem(
                    label: "length",
                    kind: .property,
                    detail: "Int",
                    documentation: .optionA("The number of characters in this string.")
                ),
                CompletionItem(
                    label: "lastIndex",
                    kind: .property,
                    detail: "Int",
                    documentation: .optionA("The index of the last character in this string (same as length - 1).")
                ),
                CompletionItem(
                    label: "isEmpty",
                    kind: .property,
                    detail: "Boolean",
                    documentation: .optionA("Tells whether this string is empty.")
                ),
                CompletionItem(
                    label: "isBlank",
                    kind: .property,
                    detail: "Boolean",
                    documentation: .optionA("Tells if all characters in this string have Unicode property \"White_Space\".")
                ),
                CompletionItem(
                    label: "isRegex",
                    kind: .property,
                    detail: "Boolean",
                    documentation: .optionA("Tells if this string is a valid regular expression according to Regex.")
                ),
                CompletionItem(
                    label: "md5",
                    kind: .property,
                    detail: "String",
                    documentation: .optionA("The MD5 hash of this string's UTF-8 byte sequence as hexadecimal string.")
                ),
                CompletionItem(
                    label: "sha1",
                    kind: .property,
                    detail: "String",
                    documentation: .optionA("The SHA-1 hash of this string's UTF-8 byte sequence.")
                ),
                CompletionItem(
                    label: "sha256",
                    kind: .property,
                    detail: "String",
                    documentation: .optionA("The SHA-256 cryptographic hash of this string's UTF-8 byte sequence as hexadecimal string.")
                ),
                CompletionItem(
                    label: "sha256Int",
                    kind: .property,
                    detail: "Int",
                    documentation: .optionA("The first 64 bits of the SHA-256 cryptographic hash of this string's UTF-8 byte sequence.")
                ),
                CompletionItem(
                    label: "base64",
                    kind: .property,
                    detail: "String",
                    documentation: .optionA("The Base64 encoding of this string's UTF-8 byte sequence.")
                ),
                CompletionItem(
                    label: "base64Decoded",
                    kind: .property,
                    detail: "String",
                    documentation: .optionA("The inverse of base64.")
                ),
                CompletionItem(
                    label: "chars",
                    kind: .property,
                    detail: "List<Char>(this.length == length)",
                    documentation: .optionA("The Unicode characters in this string.")
                ),
                CompletionItem(
                    label: "codePoints",
                    kind: .property,
                    detail: "List<Int(isBetween(0, 0x10FFFF))>(this.length == length)",
                    documentation: .optionA("The Unicode code points in this string.")
                ),

                // Methods
                CompletionItem(
                    label: "getOrNull(index: Int)",
                    kind: .function,
                    detail: "Char?",
                    documentation: .optionA("Returns the character at index, or null if index is out of range."),
                    insertText: "getOrNull()"
                ),
                CompletionItem(
                    label: "substring(start: Int, exclusiveEnd: Int)",
                    kind: .function,
                    detail: "String",
                    documentation: .optionA("Returns the substring from start until exclusiveEnd."),
                    insertText: "substring()"
                ),
                CompletionItem(
                    label: "substringOrNull(start: Int, exclusiveEnd: Int)",
                    kind: .function,
                    detail: "String?",
                    documentation: .optionA("Returns the substring from start until exclusiveEnd."),
                    insertText: "substringOrNull()"
                ),
                CompletionItem(
                    label: "repeat(count: UInt)",
                    kind: .function,
                    detail: "String",
                    documentation: .optionA("Concatenates count copies of this string."),
                    insertText: "repeat()"
                ),
                CompletionItem(
                    label: "contains(pattern: String|Regex)",
                    kind: .function,
                    detail: "Boolean",
                    documentation: .optionA("Tells whether this string contains pattern."),
                    insertText: "contains()"
                ),
                CompletionItem(
                    label: "matches(regex: Regex)",
                    kind: .function,
                    detail: "Boolean",
                    documentation: .optionA("Tells whether this string matches regex in its entirety."),
                    insertText: "matches()"
                ),
                CompletionItem(
                    label: "startsWith(pattern: String|Regex)",
                    kind: .function,
                    detail: "Boolean",
                    documentation: .optionA("Tells whether this string starts with pattern."),
                    insertText: "startsWith()"
                ),
                CompletionItem(
                    label: "endsWith(pattern: String|Regex)",
                    kind: .function,
                    detail: "Boolean",
                    documentation: .optionA("Tells whether this string ends with pattern."),
                    insertText: "endsWith()"
                ),
                CompletionItem(
                    label: "indexOf(pattern: String|Regex)",
                    kind: .function,
                    detail: "Int",
                    documentation: .optionA("Returns the zero-based index of the first occurrence of pattern in this string."),
                    insertText: "indexOf()"
                ),
                CompletionItem(
                    label: "indexOfOrNull(pattern: String|Regex)",
                    kind: .function,
                    detail: "Int?",
                    documentation: .optionA("Returns the zero-based index of the first occurrence of pattern in this string, or null if pattern does not occur in this string."),
                    insertText: "substring()"
                ),
                CompletionItem(
                    label: "lastIndexOf(pattern: String|Regex)",
                    kind: .function,
                    detail: "Int",
                    documentation: .optionA("Returns the zero-based index of the last occurrence of pattern in this string."),
                    insertText: "lastIndexOf()"
                ),
                CompletionItem(
                    label: "lastIndexOfOrNull(pattern: String|Regex)",
                    kind: .function,
                    detail: "Int?",
                    documentation: .optionA("Returns the zero-based index of the last occurrence of pattern in this string, or null if pattern does not occur in this string."),
                    insertText: "lastIndexOfOrNull()"
                ),
                CompletionItem(
                    label: "take(n: Int)",
                    kind: .function,
                    detail: "String",
                    documentation: .optionA("Returns the first n characters of this string."),
                    insertText: "take()"
                ),
                CompletionItem(
                    label: "takeWhile(predicate: (String) -> Boolean)",
                    kind: .function,
                    detail: "String",
                    documentation: .optionA("Returns the longest prefix of this string that satisfies predicate."),
                    insertText: "takeWhile()"
                ),
                CompletionItem(
                    label: "takeLast(n: Int)",
                    kind: .function,
                    detail: "String",
                    documentation: .optionA("Returns the last n characters of this string."),
                    insertText: "takeLast()"
                ),
                CompletionItem(
                    label: "takeLastWhile(predicate: (String) -> Boolean)",
                    kind: .function,
                    detail: "String",
                    documentation: .optionA("Returns the longest suffix of this string that satisfies predicate."),
                    insertText: "takeLastWhile()"
                ),
                CompletionItem(
                    label: "drop(n: Int)",
                    kind: .function,
                    detail: "String",
                    documentation: .optionA("""
                    Removes the first n characters of this string.

                    Also known as: skip

                    Returns the empty string if n is greater than or equal to length.
                    """),
                    insertText: "drop()"
                ),
                CompletionItem(
                    label: "dropWhile(predicate: (String) -> Boolean)",
                    kind: .function,
                    detail: "String",
                    documentation: .optionA("""
                    Removes the longest prefix of this string that satisfies predicate.

                    Also known as: skipWhile
                    """),
                    insertText: "dropWhile()"
                ),
                CompletionItem(
                    label: "dropLast(n: Int)",
                    kind: .function,
                    detail: "String",
                    documentation: .optionA("""
                    Removes the last n characters of this string.

                    Also known as: skipLast

                    Returns the empty string if n is greater than or equal to length.
                    """),
                    insertText: "dropLast()"
                ),
                CompletionItem(
                    label: "dropWhile(predicate: (String) -> Boolean)",
                    kind: .function,
                    detail: "String",
                    documentation: .optionA("""
                    Removes the longest prefix of this string that satisfies predicate.

                    Also known as: skipWhile
                    """),
                    insertText: "substring()"
                ),
                CompletionItem(
                    label: "dropLastWhile(predicate: (String) -> Boolean)",
                    kind: .function,
                    detail: "String",
                    documentation: .optionA("""
                    Removes the longest suffix of this string that satisfies predicate.

                    Also known as: skipLastWhile
                    """),
                    insertText: "dropLastWhile()"
                ),
                CompletionItem(
                    label: "replaceFirst(pattern: String|Regex, replacement: String)",
                    kind: .function,
                    detail: "String",
                    documentation: .optionA("""
                    Replaces the first occurrence of pattern in this string with replacement.

                    Returns this string unchanged if pattern does not occur in this string. 
                    """),
                    insertText: "replaceFirst()"
                ),
                CompletionItem(
                    label: "replaceLast(pattern: String|Regex, replacement: String)",
                    kind: .function,
                    detail: "String",
                    documentation: .optionA("""
                    Replaces the last occurrence of pattern in this string with replacement.

                    Returns this string unchanged if pattern does not occur in this string.
                    """),
                    insertText: "replaceLast()"
                ),
                CompletionItem(
                    label: "replaceAll(pattern: String|Regex, replacement: String)",
                    kind: .function,
                    detail: "String",
                    documentation: .optionA("""
                    Replaces all occurrences of pattern in this string with replacement.

                    Returns this string unchanged if pattern does not occur in this string.
                    """),
                    insertText: "replaceAll()"
                ),
                CompletionItem(
                    label: "replaceFirstMapped(pattern: String|Regex, mapper: (RegexMatch) -> String)",
                    kind: .function,
                    detail: "String",
                    documentation: .optionA("""
                    Replaces the first occurrence of pattern in this string with the return value of mapper.

                    Returns this string unchanged if pattern does not occur in this string. 
                    """),
                    insertText: "replaceFirstMapped()"
                ),
                CompletionItem(
                    label: "replaceLastMapped(pattern: String|Regex, mapper: (RegexMatch) -> String)",
                    kind: .function,
                    detail: "String",
                    documentation: .optionA("""
                    Replaces the last occurrence of pattern in this string with the return value of mapper.

                    Returns this string unchanged if pattern does not occur in this string. 
                    """),
                    insertText: "replaceLastMapped()"
                ),
                CompletionItem(
                    label: "replaceAllMapped(pattern: String|Regex, mapper: (RegexMatch) -> String)",
                    kind: .function,
                    detail: "String",
                    documentation: .optionA("""
                    Replaces all occurrences of pattern in this string with replacement.

                    Returns this string unchanged if pattern does not occur in this string.
                    """),
                    insertText: "replaceAllMapped()"
                ),
                CompletionItem(
                    label: "replaceRange(start: Int, exclusiveEnd: Int, replacement: String)",
                    kind: .function,
                    detail: "String",
                    documentation: .optionA("""
                    Replaces the characters between start and exclusiveEnd with replacement.

                    Inserts replacement at index start if start == exclusiveEnd. 
                    """),
                    insertText: "replaceRange()"
                ),
                CompletionItem(
                    label: "toUpperCase()",
                    kind: .function,
                    detail: "String",
                    documentation: .optionA("""
                    Performs a locale-independent character-by-character conversion of this string to uppercase.                   
                    """),
                    insertText: "toUpperCase()"
                ),
                CompletionItem(
                    label: "toLowerCase()",
                    kind: .function,
                    detail: "String",
                    documentation: .optionA("""
                    Performs a locale-independent character-by-character conversion of this string to lowercase.
                    """),
                    insertText: "toLowerCase()"
                ),
                CompletionItem(
                    label: "reverse()",
                    kind: .function,
                    detail: "String",
                    documentation: .optionA("""
                    Reverses the order of characters in this string.
                    """),
                    insertText: "reverse()"
                ),
                CompletionItem(
                    label: "trim()",
                    kind: .function,
                    detail: "String",
                    documentation: .optionA("""
                    Removes any leading and trailing characters with Unicode property "White_Space" from this string.

                    Also known as: strip
                    """),
                    insertText: "trim()"
                ),
                CompletionItem(
                    label: "trimStart()",
                    kind: .function,
                    detail: "String",
                    documentation: .optionA("""
                    Removes any leading characters with Unicode property "White_Space" from this string.

                    Also known as: stripLeft, stripStart, stripLeading, trimLeft, trimLeading
                    """),
                    insertText: "trimStart()"
                ),
                CompletionItem(
                    label: "trimEnd()",
                    kind: .function,
                    detail: "String",
                    documentation: .optionA("""
                    Removes any trailing characters with Unicode property "White_Space" from this string.

                    Also known as: stripRight, stripEnd, stripTrailing, trimRight, trimTrailin
                    """),
                    insertText: "trimEnd()"
                ),
                CompletionItem(
                    label: "padStart(width: Int, char: Char)",
                    kind: .function,
                    detail: "String",
                    documentation: .optionA("""
                    Increases the length of this string to width by adding leading chars.

                    Also known as: padLeft

                    Returns this string unchanged if its length is already equal to or greater than width.
                    """),
                    insertText: "padStart()"
                ),
                CompletionItem(
                    label: "padEnd(width: Int, char: Char)",
                    kind: .function,
                    detail: "String",
                    documentation: .optionA("""
                    Increases the length of this string to width by adding trailing chars.

                    Also known as: padRight

                    Returns this string unchanged if its length is already equal to or greater than width.
                    """),
                    insertText: "padEnd()"
                ),
                CompletionItem(
                    label: "split(pattern: String|Regex)",
                    kind: .function,
                    detail: "List<String>",
                    documentation: .optionA("""
                    Splits this string around matches of pattern.
                    """),
                    insertText: "split()"
                ),
                CompletionItem(
                    label: "capitalize()",
                    kind: .function,
                    detail: "String",
                    documentation: .optionA("""
                    Converts the first character of this string to title case.
                    """),
                    insertText: "capitalize()"
                ),
                CompletionItem(
                    label: "decapitalize()",
                    kind: .function,
                    detail: "String",
                    documentation: .optionA("""
                    Converts the first character of this string to lower case.
                    """),
                    insertText: "decapitalize()"
                ),
                CompletionItem(
                    label: "toInt()",
                    kind: .function,
                    detail: "Int",
                    documentation: .optionA("""
                    Parses this string as a signed decimal (base 10) integer.

                    Throws if this string cannot be parsed as a signed decimal integer, or if the integer is too large to fit into Int.
                    """),
                    insertText: "toInt()"
                ),
                CompletionItem(
                    label: "toIntOrNull()",
                    kind: .function,
                    detail: "Int?",
                    documentation: .optionA("""
                    Parses this string as a signed decimal (base 10) integer.

                    Returns null if this string cannot be parsed as a signed decimal integer, or if the integer is too large to fit into Int.
                    """),
                    insertText: "toIntOrNull()"
                ),
                CompletionItem(
                    label: "toFloat()",
                    kind: .function,
                    detail: "Float",
                    documentation: .optionA("""
                    Parses this string as a floating point number.

                    Throws if this string cannot be parsed as a floating point number.
                    """),
                    insertText: "toFloat()"
                ),
                CompletionItem(
                    label: "toFloatOrNull()",
                    kind: .function,
                    detail: "Float?",
                    documentation: .optionA("""
                    Parses this string as a floating point number.

                    Returns null if this string cannot be parsed as a floating point number.
                    """),
                    insertText: "toFloatOrNull()"
                ),
                CompletionItem(
                    label: "toBoolean()",
                    kind: .function,
                    detail: "Boolean",
                    documentation: .optionA("""
                    Parses "true" to true and "false" to false (case-insensitive).

                    Throws if this string is neither "true" nor "false" (case-insensitive).
                    """),
                    insertText: "toBoolean()"
                ),
                CompletionItem(
                    label: "toBooleanOrNull()",
                    kind: .function,
                    detail: "Boolean",
                    documentation: .optionA("""
                    Parses "true" to true and "false" to false (case-insensitive).

                    Returns null if this string is neither "true" nor "false" (case-insensitive).
                    """),
                    insertText: "toBooleanOrNull()"
                ),
            ]
        }
        if identifier == "Boolean" {
            return [
                CompletionItem(
                    label: "xor(other: Boolean)",
                    kind: .function,
                    detail: "Boolean",
                    documentation: .optionA("Tells if exactly one of this and other is true (exclusive or)."),
                    insertText: "xor()"
                ),
                CompletionItem(
                    label: "implies(other: Boolean)",
                    kind: .function,
                    detail: "Boolean",
                    documentation: .optionA("""
                    Tells if this implies other (logical consequence).

                    Note: This function does not short-circuit; other is always evaluated.
                    """),
                    insertText: "implies()"
                )
            ]
        }
        if identifier.starts(with: "Listing") {
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
