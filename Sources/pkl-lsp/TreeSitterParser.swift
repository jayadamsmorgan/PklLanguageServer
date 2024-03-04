import Foundation
import LanguageServerProtocol
import Logging
import SwiftTreeSitter
import TreeSitterPkl

public class TreeSitterParser {
    let logger: Logger

    let parser = Parser()
    var parsedTrees: [Document: MutableTree]
    var astParsedTrees: [Document: any ASTNode]

    public init(logger: Logger) {
        self.logger = logger
        let language = Language(language: tree_sitter_pkl())
        parsedTrees = [:]
        astParsedTrees = [:]
        do {
            try parser.setLanguage(language)
        } catch {
            logger.debug("Failed to set language: \(error)")
            return
        }
    }

    private func parseDocumentTreeSitterWithChanges(
        oldDocument: Document,
        newDocument: Document,
        previousParsingTree: MutableTree,
        changes _: [TextDocumentContentChangeEvent]
    ) -> MutableTree? {
        let edit = InputEdit.from(oldString: oldDocument.text, newString: newDocument.text)
        previousParsingTree.edit(edit)
        logger.debug("Tree-sitter parsing: Edit applied: \(edit)")
        if let newTree = parser.parse(tree: previousParsingTree, string: newDocument.text) {
            let changedRanges = previousParsingTree.changedRanges(from: newTree)
            logger.debug("Tree-sitter parsing: Changed ranges: \(changedRanges)")
            return newTree
        }
        return nil
    }

    public func parseDocumentTreeSitter(newDocument: Document) {
        guard let tree = parser.parse(newDocument.text) else {
            logger.error("Failed to tree-sitter parse complete source.")
            return
        }
        guard let rootNode = tree.rootNode else {
            logger.error("Failed to tree-sitter parse complete source. Root node is nil.")
            return
        }
        logger.debug("Document \(newDocument) parsed succesfully. Tree: \(tree)")
        parsedTrees[newDocument] = tree
        logger.debug("RootNode: \(PklTreeSitterSymbols(rootNode.symbol)!), range: \(rootNode.pointRange), text: \(newDocument.getTextInByteRange(rootNode.byteRange))")
        if logger.logLevel == .debug || logger.logLevel == .trace {
            listTreeSitterNodes(rootNode: rootNode, document: newDocument)
        }
        guard let astParsing = tsNodeToASTNode(node: rootNode, in: newDocument) else {
            logger.error("Failed to parse tree-sitter tree to AST tree.")
            return
        }
        astParsedTrees[newDocument] = astParsing
    }

    public func parseDocumentTreeSitter(oldDocument: Document, newDocument: Document, changes: [TextDocumentContentChangeEvent]) {
        if let previousParsingTree = parsedTrees[oldDocument] {
            if let tree = parseDocumentTreeSitterWithChanges(
                oldDocument: oldDocument,
                newDocument: newDocument,
                previousParsingTree: previousParsingTree,
                changes: changes
            ) {
                guard let rootNode = tree.rootNode else {
                    logger.error("Failed to tree-sitter parse source with changes. Root node is nil.")
                    return
                }
                parsedTrees[oldDocument] = nil
                parsedTrees[newDocument] = tree
                if logger.logLevel == .debug || logger.logLevel == .trace {
                    listTreeSitterNodes(rootNode: rootNode, document: newDocument)
                }
                guard let astParsing = tsNodeToASTNode(node: rootNode, in: newDocument) else {
                    logger.error("Failed to parse tree-sitter tree to AST tree.")
                    return
                }
                astParsedTrees[newDocument] = astParsing
                return
            }
            logger.debug("Failed to tree-sitter parse source with changes, trying to parse whole document...")
        }
        parsedTrees[oldDocument] = nil
        parseDocumentTreeSitter(newDocument: newDocument)
    }

    // List tree sitter nodes used for debugging
    private func listTreeSitterNodes(rootNode: Node, depth: Int = 0, document: Document) {
        rootNode.enumerateChildren(block: { node in
            guard let treeSitterSymbol = PklTreeSitterSymbols(node.symbol) else {
                return
            }
            logger.debug("Node: \(treeSitterSymbol), depth: \(depth), range: \(node.pointRange), text: \(document.getTextInByteRange(node.byteRange))")
            listTreeSitterNodes(rootNode: node, depth: depth + 1, document: document)
        })
    }

    private func tsNodeToASTNode(node: Node, in document: Document) -> (any ASTNode)? {
        guard let tsSymbol = PklTreeSitterSymbols(node.symbol) else {
            logger.debug("Unable to parse node with symbol \(node.symbol)")
            return nil
        }

        switch tsSymbol {
        case .sym_identifier:
            logger.debug("Starting building identifier...")
            let identifier = document.getTextInByteRange(node.byteRange)
            logger.debug("Identifier built succesfully.")
            return PklIdentifier(value: identifier, positionStart: node.pointRange.lowerBound.toPosition(), positionEnd: node.pointRange.upperBound.toPosition())

        case .anon_sym_module:
            logger.debug("Not implemented")
        case .anon_sym_extends:
            logger.debug("Not implemented")
        case .anon_sym_amends:
            logger.debug("Not implemented")
        case .anon_sym_import:
            logger.debug("Not implemented")
        case .anon_sym_as:
            logger.debug("Not implemented")
        case .anon_sym_import_STAR:
            logger.debug("Not implemented")
        case .anon_sym_class:
            logger.debug("Not implemented")
        case .anon_sym_LBRACE:
            logger.debug("Not implemented")
        case .anon_sym_RBRACE:
            logger.debug("Not implemented")
        case .anon_sym_typealias:
            logger.debug("Not implemented")
        case .anon_sym_EQ:
            logger.debug("Not implemented")
        case .anon_sym_function:
            logger.debug("Not implemented")
        case .anon_sym_AT:
            logger.debug("Not implemented")
        case .anon_sym_RBRACK:
            logger.debug("Not implemented")
        case .anon_sym_LBRACK_LBRACK:
            logger.debug("Not implemented")
        case .anon_sym_RBRACK_RBRACK:
            logger.debug("Not implemented")
        case .anon_sym_for:
            logger.debug("Not implemented")
        case .anon_sym_LPAREN:
            logger.debug("Not implemented")
        case .anon_sym_COMMA:
            logger.debug("Not implemented")
        case .anon_sym_in:
            logger.debug("Not implemented")
        case .anon_sym_RPAREN:
            logger.debug("Not implemented")
        case .anon_sym_when:
            logger.debug("Not implemented")
        case .anon_sym_DOT_DOT_DOT:
            logger.debug("Not implemented")
        case .anon_sym_DOT_DOT_DOT_QMARK:
            logger.debug("Not implemented")
        case .anon_sym_DASH_GT:
            logger.debug("Not implemented")
        case .anon_sym_COLON:
            logger.debug("Not implemented")
        case .anon_sym_unknown:
            logger.debug("Not implemented")
        case .anon_sym_nothing:
            logger.debug("Not implemented")
        case .anon_sym_QMARK:
            logger.debug("Not implemented")
        case .anon_sym_PIPE:
            logger.debug("Not implemented")
        case .anon_sym_STAR:
            logger.debug("Not implemented")
        case .anon_sym_LT:
            logger.debug("Not implemented")
        case .anon_sym_GT:
            logger.debug("Not implemented")
        case .anon_sym_out:
            logger.debug("Not implemented")
        case .anon_sym_external:
            logger.debug("Not implemented")
        case .anon_sym_abstract:
            logger.debug("Not implemented")
        case .anon_sym_open:
            logger.debug("Not implemented")
        case .anon_sym_local:
            logger.debug("Not implemented")
        case .anon_sym_hidden:
            logger.debug("Not implemented")
        case .anon_sym_fixed:
            logger.debug("Not implemented")
        case .anon_sym_const:
            logger.debug("Not implemented")
        case .sym_thisExpr:
            logger.debug("Not implemented")
        case .sym_outerExpr:
            logger.debug("Not implemented")

        case .sym_nullLiteral: // NULL LITERAL
            logger.debug("Null literal built succesfully.")
            return PklNullLiteral(positionStart: node.pointRange.lowerBound.toPosition(), positionEnd: node.pointRange.upperBound.toPosition())

        case .sym_trueLiteral: // BOOLEAN LITERAL
            logger.debug("Boolean literal built succesfully.")
            return PklBooleanLiteral(value: true, positionStart: node.pointRange.lowerBound.toPosition(), positionEnd: node.pointRange.upperBound.toPosition())

        case .sym_falseLiteral: // BOOLEAN LITERAL
            logger.debug("Boolean literal built succesfully.")
            return PklBooleanLiteral(value: false, positionStart: node.pointRange.lowerBound.toPosition(), positionEnd: node.pointRange.upperBound.toPosition())

        case .sym_intLiteral: // INTEGER LITERAL
            logger.debug("Starting building integer literal...")
            let value = document.getTextInByteRange(node.byteRange)
            logger.debug("Integer literal built succesfully.")
            return PklNumberLiteral(value: value, type: .int,
                                    positionStart: node.pointRange.lowerBound.toPosition(), positionEnd: node.pointRange.upperBound.toPosition())

        case .sym_floatLiteral: // FLOAT LITERAL
            logger.debug("Starting building float literal...")
            let value = document.getTextInByteRange(node.byteRange)
            logger.debug("Float literal built succesfully.")
            return PklNumberLiteral(value: value, type: .float,
                                    positionStart: node.pointRange.lowerBound.toPosition(), positionEnd: node.pointRange.upperBound.toPosition())

        case .anon_sym_DQUOTE:
            logger.debug("Not implemented")
        case .aux_sym_stringConstant_token1:
            logger.debug("Not implemented")
        case .anon_sym_POUND_DQUOTE:
            logger.debug("Not implemented")
        case .anon_sym_DQUOTE_POUND:
            logger.debug("Not implemented")
        case .anon_sym_POUND_POUND_DQUOTE:
            logger.debug("Not implemented")
        case .anon_sym_DQUOTE_POUND_POUND:
            logger.debug("Not implemented")
        case .anon_sym_POUND_POUND_POUND_DQUOTE:
            logger.debug("Not implemented")
        case .anon_sym_DQUOTE_POUND_POUND_POUND:
            logger.debug("Not implemented")
        case .anon_sym_POUND_POUND_POUND_POUND_DQUOTE:
            logger.debug("Not implemented")
        case .anon_sym_DQUOTE_POUND_POUND_POUND_POUND:
            logger.debug("Not implemented")
        case .anon_sym_POUND_POUND_POUND_POUND_POUND_DQUOTE:
            logger.debug("Not implemented")
        case .anon_sym_DQUOTE_POUND_POUND_POUND_POUND_POUND:
            logger.debug("Not implemented")
        case .anon_sym_POUND_POUND_POUND_POUND_POUND_POUND_DQUOTE:
            logger.debug("Not implemented")
        case .anon_sym_DQUOTE_POUND_POUND_POUND_POUND_POUND_POUND:
            logger.debug("Not implemented")
        case .anon_sym_DQUOTE_DQUOTE_DQUOTE:
            logger.debug("Not implemented")
        case .anon_sym_POUND_DQUOTE_DQUOTE_DQUOTE:
            logger.debug("Not implemented")
        case .anon_sym_DQUOTE_DQUOTE_DQUOTE_POUND:
            logger.debug("Not implemented")
        case .anon_sym_POUND_POUND_DQUOTE_DQUOTE_DQUOTE:
            logger.debug("Not implemented")
        case .anon_sym_DQUOTE_DQUOTE_DQUOTE_POUND_POUND:
            logger.debug("Not implemented")
        case .anon_sym_POUND_POUND_POUND_DQUOTE_DQUOTE_DQUOTE:
            logger.debug("Not implemented")
        case .anon_sym_DQUOTE_DQUOTE_DQUOTE_POUND_POUND_POUND:
            logger.debug("Not implemented")
        case .anon_sym_POUND_POUND_POUND_POUND_DQUOTE_DQUOTE_DQUOTE:
            logger.debug("Not implemented")
        case .anon_sym_DQUOTE_DQUOTE_DQUOTE_POUND_POUND_POUND_POUND:
            logger.debug("Not implemented")
        case .anon_sym_POUND_POUND_POUND_POUND_POUND_DQUOTE_DQUOTE_DQUOTE:
            logger.debug("Not implemented")
        case .anon_sym_DQUOTE_DQUOTE_DQUOTE_POUND_POUND_POUND_POUND_POUND:
            logger.debug("Not implemented")
        case .anon_sym_POUND_POUND_POUND_POUND_POUND_POUND_DQUOTE_DQUOTE_DQUOTE:
            logger.debug("Not implemented")
        case .anon_sym_DQUOTE_DQUOTE_DQUOTE_POUND_POUND_POUND_POUND_POUND_POUND:
            logger.debug("Not implemented")
        case .sym_escapeSequence:
            logger.debug("Not implemented")
        case .sym_escapeSequence1:
            logger.debug("Not implemented")
        case .sym_escapeSequence2:
            logger.debug("Not implemented")
        case .sym_escapeSequence3:
            logger.debug("Not implemented")
        case .sym_escapeSequence4:
            logger.debug("Not implemented")
        case .sym_escapeSequence5:
            logger.debug("Not implemented")
        case .sym_escapeSequence6:
            logger.debug("Not implemented")
        case .anon_sym_BSLASH_LPAREN:
            logger.debug("Not implemented")
        case .anon_sym_BSLASH_POUND_LPAREN:
            logger.debug("Not implemented")
        case .anon_sym_BSLASH_POUND_POUND_LPAREN:
            logger.debug("Not implemented")
        case .anon_sym_BSLASH_POUND_POUND_POUND_LPAREN:
            logger.debug("Not implemented")
        case .anon_sym_BSLASH_POUND_POUND_POUND_POUND_LPAREN:
            logger.debug("Not implemented")
        case .anon_sym_BSLASH_POUND_POUND_POUND_POUND_POUND_LPAREN:
            logger.debug("Not implemented")
        case .anon_sym_BSLASH_POUND_POUND_POUND_POUND_POUND_POUND_LPAREN:
            logger.debug("Not implemented")
        case .anon_sym_new:
            logger.debug("Not implemented")
        case .anon_sym_super:
            logger.debug("Not implemented")
        case .anon_sym_DOT:
            logger.debug("Not implemented")
        case .anon_sym_QMARK_DOT:
            logger.debug("Not implemented")
        case .anon_sym_BANG_BANG:
            logger.debug("Not implemented")
        case .anon_sym_DASH:
            logger.debug("Not implemented")
        case .anon_sym_BANG:
            logger.debug("Not implemented")
        case .anon_sym_STAR_STAR:
            logger.debug("Not implemented")
        case .anon_sym_QMARK_QMARK:
            logger.debug("Not implemented")
        case .anon_sym_SLASH:
            logger.debug("Not implemented")
        case .anon_sym_TILDE_SLASH:
            logger.debug("Not implemented")
        case .anon_sym_PERCENT:
            logger.debug("Not implemented")
        case .anon_sym_PLUS:
            logger.debug("Not implemented")
        case .anon_sym_LT_EQ:
            logger.debug("Not implemented")
        case .anon_sym_GT_EQ:
            logger.debug("Not implemented")
        case .anon_sym_EQ_EQ:
            logger.debug("Not implemented")
        case .anon_sym_BANG_EQ:
            logger.debug("Not implemented")
        case .anon_sym_AMP_AMP:
            logger.debug("Not implemented")
        case .anon_sym_PIPE_PIPE:
            logger.debug("Not implemented")
        case .anon_sym_PIPE_GT:
            logger.debug("Not implemented")
        case .anon_sym_is:
            logger.debug("Not implemented")
        case .anon_sym_if:
            logger.debug("Not implemented")
        case .anon_sym_else:
            logger.debug("Not implemented")
        case .anon_sym_let:
            logger.debug("Not implemented")
        case .anon_sym_throw:
            logger.debug("Not implemented")
        case .anon_sym_trace:
            logger.debug("Not implemented")
        case .anon_sym_read:
            logger.debug("Not implemented")
        case .anon_sym_read_QMARK:
            logger.debug("Not implemented")
        case .anon_sym_read_STAR:
            logger.debug("Not implemented")
        case .sym_lineComment:
            logger.debug("Not implemented")
        case .sym_docComment:
            logger.debug("Not implemented")
        case .sym_blockComment:
            logger.debug("Not implemented")
        case .sym__sl1_string_chars:
            logger.debug("Not implemented")
        case .sym__sl2_string_chars:
            logger.debug("Not implemented")
        case .sym__sl3_string_chars:
            logger.debug("Not implemented")
        case .sym__sl4_string_chars:
            logger.debug("Not implemented")
        case .sym__sl5_string_chars:
            logger.debug("Not implemented")
        case .sym__sl6_string_chars:
            logger.debug("Not implemented")
        case .sym__ml_string_chars:
            logger.debug("Not implemented")
        case .sym__ml1_string_chars:
            logger.debug("Not implemented")
        case .sym__ml2_string_chars:
            logger.debug("Not implemented")
        case .sym__ml3_string_chars:
            logger.debug("Not implemented")
        case .sym__ml4_string_chars:
            logger.debug("Not implemented")
        case .sym__ml5_string_chars:
            logger.debug("Not implemented")
        case .sym__ml6_string_chars:
            logger.debug("Not implemented")
        case .sym__open_square_bracket:
            logger.debug("Not implemented")
        case .sym__open_entry_bracket:
            logger.debug("Not implemented")

        case .sym_module: // MODULE (ROOT)
            logger.debug("Starting building module...")
            var contents: [any ASTNode] = []
            node.enumerateChildren(block: { childNode in
                if let astNode = tsNodeToASTNode(node: childNode, in: document) {
                    contents.append(astNode)
                }
            })
            let module = PklModule(contents: contents,
                                   positionStart: node.pointRange.lowerBound.toPosition(), positionEnd: node.pointRange.upperBound.toPosition())
            if let errors = module.diagnosticErrors() {
                logger.debug("AST Diagnostic errors: \(errors)")
            }
            logger.debug("Module built succesfully.")
            return module

        case .sym_moduleHeader:
            logger.debug("Not implemented")
        case .sym_moduleClause:
            logger.debug("Not implemented")
        case .sym_extendsOrAmendsClause:
            logger.debug("Not implemented")
        case .sym_importClause:
            logger.debug("Not implemented")
        case .sym_importGlobClause:
            logger.debug("Not implemented")
        case .sym__moduleMember:
            logger.debug("Not implemented")

        case .sym_clazz: // CLASS DECLARATION
            logger.debug("Starting building class...")
            var classNode: PklClass?
            var classKeyword: String?
            var classIdentifier: PklIdentifier?
            node.enumerateChildren(block: { childNode in
                if childNode.symbol == PklTreeSitterSymbols.sym_classBody.rawValue {
                    classNode = tsNodeToASTNode(node: childNode, in: document) as? PklClass
                    return
                }
                if childNode.symbol == PklTreeSitterSymbols.sym_identifier.rawValue {
                    classIdentifier = tsNodeToASTNode(node: childNode, in: document) as? PklIdentifier
                    return
                }
                if childNode.symbol == PklTreeSitterSymbols.anon_sym_class.rawValue {
                    classKeyword = document.getTextInByteRange(childNode.byteRange)
                    return
                }
            })
            logger.debug("Class built succesfully.")
            return PklClassDeclaration(classNode: classNode, classKeyword: classKeyword, classIdentifier: classIdentifier,
                                       positionStart: node.pointRange.lowerBound.toPosition(), positionEnd: node.pointRange.upperBound.toPosition())

        case .sym_classExtendsClause:
            logger.debug("Not implemented")

        case .sym_classBody: // CLASS BODY
            logger.debug("Starting building class body...")
            var properties: [PklClassProperty] = []
            var functions: [PklFunctionDeclaration] = []
            var leftBraceIsPresent = false
            var rightBraceIsPresent = false
            node.enumerateChildren(block: { childNode in
                if childNode.symbol == PklTreeSitterSymbols.sym_classProperty.rawValue {
                    if let property = tsNodeToASTNode(node: childNode, in: document) as? PklClassProperty {
                        properties.append(property)
                    }
                    return
                }
                if childNode.symbol == PklTreeSitterSymbols.sym_classMethod.rawValue {
                    if let function = tsNodeToASTNode(node: childNode, in: document) as? PklFunctionDeclaration {
                        functions.append(function)
                    }
                    return
                }
                if childNode.symbol == PklTreeSitterSymbols.anon_sym_LBRACE.rawValue {
                    let brace = document.getTextInByteRange(childNode.byteRange)
                    if brace == "{" {
                        leftBraceIsPresent = true
                    }
                    return
                }
                if childNode.symbol == PklTreeSitterSymbols.anon_sym_RBRACE.rawValue {
                    let brace = document.getTextInByteRange(childNode.byteRange)
                    if brace == "}" {
                        rightBraceIsPresent = true
                    }
                    return
                }
            })
            logger.debug("Class body built succesfully.")
            return PklClass(properties: properties, functions: functions, leftBraceIsPresent: leftBraceIsPresent, rightBraceIsPresent: rightBraceIsPresent,
                            positionStart: node.pointRange.lowerBound.toPosition(), positionEnd: node.pointRange.upperBound.toPosition())

        case .sym_typeAlias:
            logger.debug("Not implemented")

        case .sym_classProperty: // CLASS PROPERTY
            logger.debug("Starting building class property...")

            // Problem here: object amending is not being parsed with tree-sitter so we need to find a way to parse it.
            // The best solution is of course to make it work upstream in tree-sitter-pkl, but we may need to find a workaround for now.
            // PklClassProperty should also be able to handle the case where the object is being amended.
            //
            // This is essential to provide property and function completions for amended object and other features.
            //
            // Example:
            // ```
            // class TestObject {
            //     testProperty: Int = 1
            // }
            //
            // testObject (TestObject) {
            //     testProperty = 2
            // }
            // ```
            // In the example above `(TestObject)` is the object amending and it's not being parsed

            var propertyIdentifier: PklIdentifier?
            var typeAnnotation: PklTypeAnnotation?
            var value: (any ASTNode)? // Can be either a PklObjectBody or a PklValue
            var isHidden = false
            var isEqualsPresent = false
            node.enumerateChildren(block: { childNode in
                if childNode.symbol == PklTreeSitterSymbols.sym_identifier.rawValue {
                    propertyIdentifier = tsNodeToASTNode(node: childNode, in: document) as? PklIdentifier
                    return
                }
                if childNode.symbol == PklTreeSitterSymbols.sym_typeAnnotation.rawValue {
                    typeAnnotation = tsNodeToASTNode(node: childNode, in: document) as? PklTypeAnnotation
                    return
                }
                if childNode.symbol == PklTreeSitterSymbols.sym_objectBody.rawValue {
                    value = tsNodeToASTNode(node: childNode, in: document)
                    return
                }
                if childNode.symbol == PklTreeSitterSymbols.anon_sym_EQ.rawValue {
                    isEqualsPresent = true
                    if let nextSibling = childNode.nextSibling {
                        value = tsNodeToASTNode(node: nextSibling, in: document)
                    }
                    return
                }
                if childNode.symbol == PklTreeSitterSymbols.anon_sym_hidden.rawValue {
                    isHidden = true
                    return
                }
            })
            logger.debug("Class property built succesfully.")
            return PklClassProperty(identifier: propertyIdentifier, typeAnnotation: typeAnnotation, isEqualsPresent: isEqualsPresent, value: value, isHidden: isHidden,
                                    positionStart: node.pointRange.lowerBound.toPosition(), positionEnd: node.pointRange.upperBound.toPosition())

        case .sym_classMethod:
            logger.debug("Starting building class method...")
            var functionValue: (any ASTNode)?
            var body: PklClassFunctionBody?
            node.enumerateChildren(block: { childNode in
                if childNode.symbol == PklTreeSitterSymbols.sym_methodHeader.rawValue {
                    body = tsNodeToASTNode(node: childNode, in: document) as? PklClassFunctionBody
                    return
                }
                // TODO: parse function value && type checking
            })
            logger.debug("Class method built succesfully.")
            return PklFunctionDeclaration(body: body, functionValue: functionValue,
                                          positionStart: node.pointRange.lowerBound.toPosition(), positionEnd: node.pointRange.upperBound.toPosition())

        case .sym_methodHeader: // METHOD HEADER
            logger.debug("Starting building method header...")
            var isFunctionKeywordPresent = false
            var identifier: PklIdentifier?
            var typeAnnotation: PklTypeAnnotation?
            var params: PklFunctionParameterList?
            node.enumerateChildren(block: { childNode in
                if childNode.symbol == PklTreeSitterSymbols.anon_sym_function.rawValue {
                    isFunctionKeywordPresent = true
                    return
                }
                if childNode.symbol == PklTreeSitterSymbols.sym_identifier.rawValue {
                    identifier = tsNodeToASTNode(node: childNode, in: document) as? PklIdentifier
                    return
                }
                if childNode.symbol == PklTreeSitterSymbols.sym_typeAnnotation.rawValue {
                    typeAnnotation = tsNodeToASTNode(node: childNode, in: document) as? PklTypeAnnotation
                    return
                }
                if childNode.symbol == PklTreeSitterSymbols.sym_parameterList.rawValue {
                    params = tsNodeToASTNode(node: childNode, in: document) as? PklFunctionParameterList
                    return
                }
            })
            logger.debug("Method header built succesfully.")
            return PklClassFunctionBody(isFunctionKeywordPresent: isFunctionKeywordPresent, identifier: identifier, params: params, typeAnnotation: typeAnnotation,
                                        positionStart: node.pointRange.upperBound.toPosition(), positionEnd: node.pointRange.lowerBound.toPosition())

        case .sym_annotation:
            logger.debug("Not implemented")

        case .sym_objectBody: // OBJECT BODY
            logger.debug("Starting building object body...")
            var properties: [PklObjectProperty] = []
            var leftBraceIsPresent = false
            var rightBraceIsPresent = false
            node.enumerateChildren(block: { childNode in
                if childNode.symbol == PklTreeSitterSymbols.sym_objectProperty.rawValue {
                    if let property = tsNodeToASTNode(node: childNode, in: document) as? PklObjectProperty {
                        properties.append(property)
                    }
                    return
                }
                if childNode.symbol == PklTreeSitterSymbols.anon_sym_LBRACE.rawValue {
                    let brace = document.getTextInByteRange(childNode.byteRange)
                    if brace == "{" {
                        leftBraceIsPresent = true
                    }
                    return
                }
                if childNode.symbol == PklTreeSitterSymbols.anon_sym_RBRACE.rawValue {
                    let brace = document.getTextInByteRange(childNode.byteRange)
                    if brace == "}" {
                        rightBraceIsPresent = true
                    }
                    return
                }
            })
            logger.debug("Object body built succesfully.")
            return PklObjectBody(properties: properties, isLeftBracePresent: leftBraceIsPresent, isRightBracePresent: rightBraceIsPresent,
                                 positionStart: node.pointRange.lowerBound.toPosition(), positionEnd: node.pointRange.upperBound.toPosition())

        case .sym__objectMember:
            logger.debug("Not implemented")

        case .sym_objectProperty: // OBJECT PROPERTY
            logger.debug("Starting building object property...")
            var identifier: PklIdentifier?
            var typeAnnotation: PklTypeAnnotation?
            var value: (any ASTNode)?
            node.enumerateChildren(block: { childNode in
                if childNode.symbol == PklTreeSitterSymbols.sym_identifier.rawValue {
                    identifier = tsNodeToASTNode(node: childNode, in: document) as? PklIdentifier
                    return
                }
                if childNode.symbol == PklTreeSitterSymbols.sym_typeAnnotation.rawValue {
                    typeAnnotation = tsNodeToASTNode(node: childNode, in: document) as? PklTypeAnnotation
                    return
                }
                if childNode.symbol == PklTreeSitterSymbols.sym_objectBody.rawValue {
                    value = tsNodeToASTNode(node: childNode, in: document)
                    return
                }
            })
            return PklObjectProperty(identifier: identifier, typeAnnotation: typeAnnotation, value: value,
                                     positionStart: node.pointRange.lowerBound.toPosition(), positionEnd: node.pointRange.upperBound.toPosition())

        case .sym_objectMethod:
            logger.debug("Not implemented")
        case .sym_objectEntry:
            logger.debug("Not implemented")
        case .sym_objectElement:
            logger.debug("Not implemented")
        case .sym_objectPredicate:
            logger.debug("Not implemented")
        case .sym_forGenerator:
            logger.debug("Not implemented")
        case .sym_whenGenerator:
            logger.debug("Not implemented")
        case .sym_objectSpread:
            logger.debug("Not implemented")
        case .sym_objectBodyParameters:
            logger.debug("Not implemented")

        case .sym_typeAnnotation: // TYPE ANNOTATION
            logger.debug("Starting building type annotation...")
            var type: PklType?
            var colonIsPresent = false
            node.enumerateChildren(block: { childNode in
                if childNode.symbol == PklTreeSitterSymbols.anon_sym_COLON.rawValue {
                    colonIsPresent = true
                    return
                }
                if childNode.symbol == PklTreeSitterSymbols.sym_type.rawValue {
                    type = tsNodeToASTNode(node: childNode, in: document) as? PklType
                    return
                }
            })
            logger.debug("Type annotation built succesfully.")
            return PklTypeAnnotation(type: type, colonIsPresent: colonIsPresent, positionStart: node.pointRange.lowerBound.toPosition(),
                                     positionEnd: node.pointRange.upperBound.toPosition())

        case .sym_type: // TYPE
            logger.debug("Starting building type...")
            let typeIdentifier = document.getTextInByteRange(node.byteRange)
            logger.debug("Type built succesfully.")
            return PklType(identifier: typeIdentifier,
                           positionStart: node.pointRange.lowerBound.toPosition(), positionEnd: node.pointRange.upperBound.toPosition())

        case .sym_typeArgumentList:
            logger.debug("Not implemented")
        case .sym_typeParameterList:
            logger.debug("Not implemented")
        case .sym_typeParameter:
            logger.debug("Not implemented")
        case .sym_parameterList: // PARAMETER LIST
            logger.debug("Starting building parameter list...")
            var parameters: [PklFunctionParameter] = []
            var leftParenIsPresent = false
            var rightParenIsPresent = false
            var commasAmount = 0
            node.enumerateChildren(block: { childNode in
                if childNode.symbol == PklTreeSitterSymbols.anon_sym_LPAREN.rawValue {
                    let leftParen = document.getTextInByteRange(childNode.byteRange)
                    if leftParen == "(" {
                        leftParenIsPresent = true
                    }
                    return
                }
                if childNode.symbol == PklTreeSitterSymbols.anon_sym_RPAREN.rawValue {
                    let rightParen = document.getTextInByteRange(childNode.byteRange)
                    if rightParen == ")" {
                        rightParenIsPresent = true
                    }
                    return
                }
                if childNode.symbol == PklTreeSitterSymbols.anon_sym_COMMA.rawValue {
                    commasAmount += 1
                    return
                }
                if childNode.symbol == PklTreeSitterSymbols.sym_typedIdentifier.rawValue {
                    if let parameter = tsNodeToASTNode(node: childNode, in: document) as? PklFunctionParameter {
                        parameters.append(parameter)
                    }
                    return
                }
            })
            logger.debug("Parameter list built succesfully.")
            return PklFunctionParameterList(parameters: parameters, isLeftParenPresent: leftParenIsPresent, isRightParenPresent: rightParenIsPresent,
                                            positionStart: node.pointRange.lowerBound.toPosition(), positionEnd: node.pointRange.upperBound.toPosition())

        case .sym_argumentList:
            logger.debug("Not implemented")
        case .sym_modifier:
            logger.debug("Not implemented")
        case .sym__expr:
            logger.debug("Not implemented")
        case .sym_variableObjectLiteral:
            logger.debug("Not implemented")
        case .sym__expr2:
            logger.debug("Not implemented")
        case .sym_parenthesizedExpr:
            logger.debug("Not implemented")
        case .sym_moduleExpr:
            logger.debug("Not implemented")
        case .sym_variableExpr:
            logger.debug("Not implemented")
        case .sym_stringConstant:
            logger.debug("Not implemented")

        case .sym_slStringLiteral: // SINGLE-LINE STRING LITERAL
            logger.debug("Starting building single-line string literal...")
            let value: String? = document.getTextInByteRange(node.byteRange)
            logger.debug("Single-line string literal built succesfully.")
            return PklStringLiteral(value: value, positionStart: node.pointRange.lowerBound.toPosition(), positionEnd: node.pointRange.upperBound.toPosition())

        case .sym_mlStringLiteral: // MULTI-LINE STRING LITERAL
            logger.debug("Starting building multi-line string literal...")
            let value: String? = document.getTextInByteRange(node.byteRange)
            logger.debug("Multi-line string literal built succesfully.")
            return PklStringLiteral(value: value, positionStart: node.pointRange.lowerBound.toPosition(), positionEnd: node.pointRange.upperBound.toPosition())

        case .sym_interpolationExpr:
            logger.debug("Not implemented")
        case .sym_interpolationExpr1:
            logger.debug("Not implemented")
        case .sym_interpolationExpr2:
            logger.debug("Not implemented")
        case .sym_interpolationExpr3:
            logger.debug("Not implemented")
        case .sym_interpolationExpr4:
            logger.debug("Not implemented")
        case .sym_interpolationExpr5:
            logger.debug("Not implemented")
        case .sym_interpolationExpr6:
            logger.debug("Not implemented")
        case .sym_newExpr:
            logger.debug("Not implemented")
        case .sym_objectLiteral:
            logger.debug("Not implemented")
        case .sym_methodCallExpr:
            logger.debug("Not implemented")
        case .sym_propertyCallExpr:
            logger.debug("Not implemented")
        case .sym_subscriptExpr:
            logger.debug("Not implemented")
        case .sym_unaryExpr:
            logger.debug("Not implemented")
        case .sym_binaryExprRightAssoc:
            logger.debug("Not implemented")
        case .sym_binaryExpr:
            logger.debug("Not implemented")
        case .sym_isExpr:
            logger.debug("Not implemented")
        case .sym_asExpr:
            logger.debug("Not implemented")
        case .sym_ifExpr:
            logger.debug("Not implemented")
        case .sym_letExpr:
            logger.debug("Not implemented")
        case .sym_throwExpr:
            logger.debug("Not implemented")
        case .sym_traceExpr:
            logger.debug("Not implemented")
        case .sym_readExpr:
            logger.debug("Not implemented")
        case .sym_readOrNullExpr:
            logger.debug("Not implemented")
        case .sym_readGlobExpr:
            logger.debug("Not implemented")
        case .sym_importExpr:
            logger.debug("Not implemented")
        case .sym_importGlobExpr:
            logger.debug("Not implemented")
        case .sym_functionLiteral:
            logger.debug("Not implemented")
        case .sym_qualifiedIdentifier:
            logger.debug("Not implemented")

        case .sym_typedIdentifier: // TYPED IDENTIFIER
            logger.debug("Starting building typed identifier...")
            var identifier: PklIdentifier?
            var typeAnnotation: PklTypeAnnotation?
            node.enumerateChildren(block: { childNode in
                if childNode.symbol == PklTreeSitterSymbols.sym_identifier.rawValue {
                    identifier = tsNodeToASTNode(node: childNode, in: document) as? PklIdentifier
                    return
                }
                if childNode.symbol == PklTreeSitterSymbols.sym_typeAnnotation.rawValue {
                    typeAnnotation = tsNodeToASTNode(node: childNode, in: document) as? PklTypeAnnotation
                    return
                }
            })
            logger.debug("Typed identifier built succesfully.")
            return PklFunctionParameter(identifier: identifier, typeAnnotation: typeAnnotation,
                                        positionStart: node.pointRange.lowerBound.toPosition(), positionEnd: node.pointRange.upperBound.toPosition())

        case .aux_sym_module_repeat1:
            logger.debug("Not implemented")
        case .aux_sym_module_repeat2:
            logger.debug("Not implemented")
        case .aux_sym_moduleHeader_repeat1:
            logger.debug("Not implemented")
        case .aux_sym_moduleClause_repeat1:
            logger.debug("Not implemented")
        case .aux_sym_classBody_repeat1:
            logger.debug("Not implemented")
        case .aux_sym_classProperty_repeat1:
            logger.debug("Not implemented")
        case .aux_sym_objectBody_repeat1:
            logger.debug("Not implemented")
        case .aux_sym_objectBodyParameters_repeat1:
            logger.debug("Not implemented")
        case .aux_sym_type_repeat1:
            logger.debug("Not implemented")
        case .aux_sym_type_repeat2:
            logger.debug("Not implemented")
        case .aux_sym_typeParameterList_repeat1:
            logger.debug("Not implemented")
        case .aux_sym_stringConstant_repeat1:
            logger.debug("Not implemented")
        case .aux_sym_stringConstant_repeat2:
            logger.debug("Not implemented")
        case .aux_sym_slStringLiteral_repeat1:
            logger.debug("Not implemented")
        case .aux_sym_slStringLiteral_repeat2:
            logger.debug("Not implemented")
        case .aux_sym_slStringLiteral_repeat3:
            logger.debug("Not implemented")
        case .aux_sym_slStringLiteral_repeat4:
            logger.debug("Not implemented")
        case .aux_sym_slStringLiteral_repeat5:
            logger.debug("Not implemented")
        case .aux_sym_slStringLiteral_repeat6:
            logger.debug("Not implemented")
        case .aux_sym_slStringLiteral_repeat7:
            logger.debug("Not implemented")
        case .aux_sym_mlStringLiteral_repeat1:
            logger.debug("Not implemented")
        case .aux_sym_mlStringLiteral_repeat2:
            logger.debug("Not implemented")
        case .aux_sym_mlStringLiteral_repeat3:
            logger.debug("Not implemented")
        case .aux_sym_mlStringLiteral_repeat4:
            logger.debug("Not implemented")
        case .aux_sym_mlStringLiteral_repeat5:
            logger.debug("Not implemented")
        case .aux_sym_mlStringLiteral_repeat6:
            logger.debug("Not implemented")
        case .aux_sym_mlStringLiteral_repeat7:
            logger.debug("Not implemented")
        case .aux_sym_qualifiedIdentifier_repeat1:
            logger.debug("Not implemented")
        }
        return nil
    }
}

public extension Point {
    func toPosition() -> Position {
        Position((Int(row), Int(column)))
    }
}
