import Foundation
import Logging
import LanguageServerProtocol
import SwiftTreeSitter
import TreeSitterPkl

public struct Change {
    let positionStart: Position
    let positionEnd: Position
    let oldText: String
    let newText: String
}

// The incremental parsing really stinks and works not so well yet. It's a bit of a mess. But it's a start. Don't judge.
public class TreeSitterParser {

    let logger: Logger

    let parser = Parser()
    var parsedTrees: [Document : MutableTree]

    public init(logger: Logger) {
        self.logger = logger
        let language = Language(language: tree_sitter_pkl())
        parsedTrees = [:]
        do {
            try parser.setLanguage(language)
        } catch {
            logger.debug("Failed to set language: \(error)")
            return
        }
    }

    // Helper function to find change indices in two strings
    private func findChangeIndices(firstString: String, secondString: String) -> (firstChange: Int?, lastChangeInFirst: Int?, lastNewCharacterInSecond: Int?) {
        let firstChars = Array(firstString)
        let secondChars = Array(secondString)

        let firstChange = zip(firstChars, secondChars).enumerated().first { $1.0 != $1.1 }?.offset

        let reversedFirstChars = firstChars.reversed()
        let reversedSecondChars = secondChars.reversed()
        let lastChangeInFirst = zip(reversedFirstChars, reversedSecondChars).enumerated().first { $1.0 != $1.1 }?.offset

        let lastChangeInFirstCorrected = lastChangeInFirst != nil ? firstString.count - 1 - lastChangeInFirst! : nil

        let lastNewCharacterInSecond = secondString.isEmpty ? nil : secondString.count - 1

        return (firstChange, lastChangeInFirstCorrected, lastNewCharacterInSecond)
    }

    // Helper function to find row and column by character index in a multiline string
    private func findRowAndColumn(forIndex index: Int, inString string: String) -> Point? {
        let lines = string.split(separator: "\n", omittingEmptySubsequences: false)
        var cumulativeCount = 0
        for (i, line) in lines.enumerated() {
            if cumulativeCount + line.count + 1 > index { // +1 for the newline character
                return Point(row: i, column: index - cumulativeCount)
            }
            cumulativeCount += line.count + 1
        }
        return nil
    }

    private func calculateInputEdit(
        oldText: String,
        newText: String
    ) -> InputEdit? {

        let changeIndices = findChangeIndices(firstString: oldText, secondString: newText)

        guard let firstChange = changeIndices.firstChange,
              let lastChangeInFirst = changeIndices.lastChangeInFirst,
              let lastNewCharacterInSecond = changeIndices.lastNewCharacterInSecond else {
            logger.debug("Tree-sitter parsing: Failed to calculate change indices.")
            return nil
        }

        guard let startingPoint = findRowAndColumn(forIndex: firstChange, inString: oldText),
              let oldEndingPoint = findRowAndColumn(forIndex: lastChangeInFirst, inString: oldText),
              let newEndingPoint = findRowAndColumn(forIndex: lastNewCharacterInSecond, inString: newText) else {
            logger.debug("Tree-sitter parsing: Failed to calculate row and column for change indices.")
            return nil
        }

        return InputEdit(
            startByte: firstChange,
            oldEndByte: lastChangeInFirst,
            newEndByte: lastNewCharacterInSecond,
            startPoint: startingPoint,
            oldEndPoint: oldEndingPoint,
            newEndPoint: newEndingPoint
        )
    }

    public func parseDocumentTreeSitterWithChanges(
        oldDocument: Document,
        newDocument: Document,
        previousParsingTree: MutableTree,
        changes: [TextDocumentContentChangeEvent]
    ) -> MutableTree? {
        var changesProcessed = false
        for _ in changes {
            guard let edit = calculateInputEdit(oldText: oldDocument.text, newText: newDocument.text) else {
                logger.debug("Tree-sitter parsing: Failed to calculate input edit.")
                return nil
            }
            previousParsingTree.edit(edit)
            logger.debug("Tree-sitter parsing: Edit applied: \(edit)")
            changesProcessed = true
        }
        if changesProcessed {
            logger.debug("Tree-sitter parsing: Changes processed.")
            return previousParsingTree
        }
        logger.debug("Tree-sitter parsing: No changes processed.")
        return nil
    }

    public func parseDocumentTreeSitter(newDocument: Document) -> MutableTree? {
        guard let tree = parser.parse(newDocument.text) else {
            logger.debug("Failed to tree-sitter parse complete source.")
            return nil
        }
        guard let rootNode = tree.rootNode else {
            logger.debug("Failed to tree-sitter parse complete source. Root node is nil.")
            return nil
        }
        logger.debug("Document \(newDocument) parsed succesfully. Tree: \(tree)")
        parsedTrees[newDocument] = tree
        logger.debug("RootNode: \(PklTreeSitterSymbols(rootNode.symbol)!), range: \(rootNode.pointRange), text: \(newDocument.getTextInByteRange(rootNode.byteRange))")
        parseNodes(rootNode: rootNode, document: newDocument)
        let rootASTNode = tsNodeToASTNode(node: rootNode, in: newDocument)
        logger.debug("Root AST Node: \(rootASTNode), error: \(rootASTNode?.error())")
        return tree
    }

    public func parseDocumentTreeSitter(oldDocument: Document, newDocument: Document, changes: [TextDocumentContentChangeEvent]) -> MutableTree? {
        if let previousParsingTree = parsedTrees[oldDocument] {
            if let tree = parseDocumentTreeSitterWithChanges(
                oldDocument: oldDocument,
                newDocument: newDocument,
                previousParsingTree: previousParsingTree,
                changes: changes
            ) {
                guard let rootNode = tree.rootNode else {
                    logger.debug("Failed to tree-sitter parse source with changes. Root node is nil.")
                    return nil
                }
                parsedTrees[oldDocument] = nil
                parsedTrees[newDocument] = tree
                parseNodes(rootNode: rootNode, document: newDocument)
                let rootASRNode = tsNodeToASTNode(node: rootNode, in: newDocument)
                return tree
            }
            logger.debug("Failed to tree-sitter parse source with changes, trying to parse whole document...")
        }

        parsedTrees[oldDocument] = nil

        return parseDocumentTreeSitter(newDocument: newDocument)
    }

    private func parseNodes(rootNode: Node, depth: Int = 0, document: Document) {
        rootNode.enumerateChildren(block: { node in
            guard let treeSitterSymbol = PklTreeSitterSymbols(node.symbol) else {
                return
            }
            logger.debug("Node: \(treeSitterSymbol), depth: \(depth), range: \(node.pointRange), text: \(document.getTextInByteRange(node.byteRange))")
            parseNodes(rootNode: node, depth: depth + 1, document: document)
        })
    }

    private func tsNodeToASTNode(node: Node, in document: Document) -> (any ASTNode)? {
        guard let tsSymbol = PklTreeSitterSymbols.init(node.symbol) else {
            logger.debug("Unable to parse node with symbol \(node.symbol)")
            return nil
        }
        switch tsSymbol {
        case .sym_identifier:
            self.logger.debug("Not implemented")
        case .anon_sym_module:
            self.logger.debug("Not implemented")
        case .anon_sym_extends:
            self.logger.debug("Not implemented")
        case .anon_sym_amends:
            self.logger.debug("Not implemented")
        case .anon_sym_import:
            self.logger.debug("Not implemented")
        case .anon_sym_as:
            self.logger.debug("Not implemented")
        case .anon_sym_import_STAR:
            self.logger.debug("Not implemented")
        case .anon_sym_class:
            self.logger.debug("Not implemented")
        case .anon_sym_LBRACE:
            self.logger.debug("Not implemented")
        case .anon_sym_RBRACE:
            self.logger.debug("Not implemented")
        case .anon_sym_typealias:
            self.logger.debug("Not implemented")
        case .anon_sym_EQ:
            self.logger.debug("Not implemented")
        case .anon_sym_function:
            self.logger.debug("Not implemented")
        case .anon_sym_AT:
            self.logger.debug("Not implemented")
        case .anon_sym_RBRACK:
            self.logger.debug("Not implemented")
        case .anon_sym_LBRACK_LBRACK:
            self.logger.debug("Not implemented")
        case .anon_sym_RBRACK_RBRACK:
            self.logger.debug("Not implemented")
        case .anon_sym_for:
            self.logger.debug("Not implemented")
        case .anon_sym_LPAREN:
            self.logger.debug("Not implemented")
        case .anon_sym_COMMA:
            self.logger.debug("Not implemented")
        case .anon_sym_in:
            self.logger.debug("Not implemented")
        case .anon_sym_RPAREN:
            self.logger.debug("Not implemented")
        case .anon_sym_when:
            self.logger.debug("Not implemented")
        case .anon_sym_DOT_DOT_DOT:
            self.logger.debug("Not implemented")
        case .anon_sym_DOT_DOT_DOT_QMARK:
            self.logger.debug("Not implemented")
        case .anon_sym_DASH_GT:
            self.logger.debug("Not implemented")
        case .anon_sym_COLON:
            self.logger.debug("Not implemented")
        case .anon_sym_unknown:
            self.logger.debug("Not implemented")
        case .anon_sym_nothing:
            self.logger.debug("Not implemented")
        case .anon_sym_QMARK:
            self.logger.debug("Not implemented")
        case .anon_sym_PIPE:
            self.logger.debug("Not implemented")
        case .anon_sym_STAR:
            self.logger.debug("Not implemented")
        case .anon_sym_LT:
            self.logger.debug("Not implemented")
        case .anon_sym_GT:
            self.logger.debug("Not implemented")
        case .anon_sym_out:
            self.logger.debug("Not implemented")
        case .anon_sym_external:
            self.logger.debug("Not implemented")
        case .anon_sym_abstract:
            self.logger.debug("Not implemented")
        case .anon_sym_open:
            self.logger.debug("Not implemented")
        case .anon_sym_local:
            self.logger.debug("Not implemented")
        case .anon_sym_hidden:
            self.logger.debug("Not implemented")
        case .anon_sym_fixed:
            self.logger.debug("Not implemented")
        case .anon_sym_const:
            self.logger.debug("Not implemented")
        case .sym_thisExpr:
            self.logger.debug("Not implemented")
        case .sym_outerExpr:
            self.logger.debug("Not implemented")
        case .sym_nullLiteral:
            self.logger.debug("Not implemented")
        case .sym_trueLiteral:
            self.logger.debug("Not implemented")
        case .sym_falseLiteral:
            self.logger.debug("Not implemented")
        case .sym_intLiteral:
            self.logger.debug("Not implemented")
        case .sym_floatLiteral:
            self.logger.debug("Not implemented")
        case .anon_sym_DQUOTE:
            self.logger.debug("Not implemented")
        case .aux_sym_stringConstant_token1:
            self.logger.debug("Not implemented")
        case .anon_sym_POUND_DQUOTE:
            self.logger.debug("Not implemented")
        case .anon_sym_DQUOTE_POUND:
            self.logger.debug("Not implemented")
        case .anon_sym_POUND_POUND_DQUOTE:
            self.logger.debug("Not implemented")
        case .anon_sym_DQUOTE_POUND_POUND:
            self.logger.debug("Not implemented")
        case .anon_sym_POUND_POUND_POUND_DQUOTE:
            self.logger.debug("Not implemented")
        case .anon_sym_DQUOTE_POUND_POUND_POUND:
            self.logger.debug("Not implemented")
        case .anon_sym_POUND_POUND_POUND_POUND_DQUOTE:
            self.logger.debug("Not implemented")
        case .anon_sym_DQUOTE_POUND_POUND_POUND_POUND:
            self.logger.debug("Not implemented")
        case .anon_sym_POUND_POUND_POUND_POUND_POUND_DQUOTE:
            self.logger.debug("Not implemented")
        case .anon_sym_DQUOTE_POUND_POUND_POUND_POUND_POUND:
            self.logger.debug("Not implemented")
        case .anon_sym_POUND_POUND_POUND_POUND_POUND_POUND_DQUOTE:
            self.logger.debug("Not implemented")
        case .anon_sym_DQUOTE_POUND_POUND_POUND_POUND_POUND_POUND:
            self.logger.debug("Not implemented")
        case .anon_sym_DQUOTE_DQUOTE_DQUOTE:
            self.logger.debug("Not implemented")
        case .anon_sym_POUND_DQUOTE_DQUOTE_DQUOTE:
            self.logger.debug("Not implemented")
        case .anon_sym_DQUOTE_DQUOTE_DQUOTE_POUND:
            self.logger.debug("Not implemented")
        case .anon_sym_POUND_POUND_DQUOTE_DQUOTE_DQUOTE:
            self.logger.debug("Not implemented")
        case .anon_sym_DQUOTE_DQUOTE_DQUOTE_POUND_POUND:
            self.logger.debug("Not implemented")
        case .anon_sym_POUND_POUND_POUND_DQUOTE_DQUOTE_DQUOTE:
            self.logger.debug("Not implemented")
        case .anon_sym_DQUOTE_DQUOTE_DQUOTE_POUND_POUND_POUND:
            self.logger.debug("Not implemented")
        case .anon_sym_POUND_POUND_POUND_POUND_DQUOTE_DQUOTE_DQUOTE:
            self.logger.debug("Not implemented")
        case .anon_sym_DQUOTE_DQUOTE_DQUOTE_POUND_POUND_POUND_POUND:
            self.logger.debug("Not implemented")
        case .anon_sym_POUND_POUND_POUND_POUND_POUND_DQUOTE_DQUOTE_DQUOTE:
            self.logger.debug("Not implemented")
        case .anon_sym_DQUOTE_DQUOTE_DQUOTE_POUND_POUND_POUND_POUND_POUND:
            self.logger.debug("Not implemented")
        case .anon_sym_POUND_POUND_POUND_POUND_POUND_POUND_DQUOTE_DQUOTE_DQUOTE:
            self.logger.debug("Not implemented")
        case .anon_sym_DQUOTE_DQUOTE_DQUOTE_POUND_POUND_POUND_POUND_POUND_POUND:
            self.logger.debug("Not implemented")
        case .sym_escapeSequence:
            self.logger.debug("Not implemented")
        case .sym_escapeSequence1:
            self.logger.debug("Not implemented")
        case .sym_escapeSequence2:
            self.logger.debug("Not implemented")
        case .sym_escapeSequence3:
            self.logger.debug("Not implemented")
        case .sym_escapeSequence4:
            self.logger.debug("Not implemented")
        case .sym_escapeSequence5:
            self.logger.debug("Not implemented")
        case .sym_escapeSequence6:
            self.logger.debug("Not implemented")
        case .anon_sym_BSLASH_LPAREN:
            self.logger.debug("Not implemented")
        case .anon_sym_BSLASH_POUND_LPAREN:
            self.logger.debug("Not implemented")
        case .anon_sym_BSLASH_POUND_POUND_LPAREN:
            self.logger.debug("Not implemented")
        case .anon_sym_BSLASH_POUND_POUND_POUND_LPAREN:
            self.logger.debug("Not implemented")
        case .anon_sym_BSLASH_POUND_POUND_POUND_POUND_LPAREN:
            self.logger.debug("Not implemented")
        case .anon_sym_BSLASH_POUND_POUND_POUND_POUND_POUND_LPAREN:
            self.logger.debug("Not implemented")
        case .anon_sym_BSLASH_POUND_POUND_POUND_POUND_POUND_POUND_LPAREN:
            self.logger.debug("Not implemented")
        case .anon_sym_new:
            self.logger.debug("Not implemented")
        case .anon_sym_super:
            self.logger.debug("Not implemented")
        case .anon_sym_DOT:
            self.logger.debug("Not implemented")
        case .anon_sym_QMARK_DOT:
            self.logger.debug("Not implemented")
        case .anon_sym_BANG_BANG:
            self.logger.debug("Not implemented")
        case .anon_sym_DASH:
            self.logger.debug("Not implemented")
        case .anon_sym_BANG:
            self.logger.debug("Not implemented")
        case .anon_sym_STAR_STAR:
            self.logger.debug("Not implemented")
        case .anon_sym_QMARK_QMARK:
            self.logger.debug("Not implemented")
        case .anon_sym_SLASH:
            self.logger.debug("Not implemented")
        case .anon_sym_TILDE_SLASH:
            self.logger.debug("Not implemented")
        case .anon_sym_PERCENT:
            self.logger.debug("Not implemented")
        case .anon_sym_PLUS:
            self.logger.debug("Not implemented")
        case .anon_sym_LT_EQ:
            self.logger.debug("Not implemented")
        case .anon_sym_GT_EQ:
            self.logger.debug("Not implemented")
        case .anon_sym_EQ_EQ:
            self.logger.debug("Not implemented")
        case .anon_sym_BANG_EQ:
            self.logger.debug("Not implemented")
        case .anon_sym_AMP_AMP:
            self.logger.debug("Not implemented")
        case .anon_sym_PIPE_PIPE:
            self.logger.debug("Not implemented")
        case .anon_sym_PIPE_GT:
            self.logger.debug("Not implemented")
        case .anon_sym_is:
            self.logger.debug("Not implemented")
        case .anon_sym_if:
            self.logger.debug("Not implemented")
        case .anon_sym_else:
            self.logger.debug("Not implemented")
        case .anon_sym_let:
            self.logger.debug("Not implemented")
        case .anon_sym_throw:
            self.logger.debug("Not implemented")
        case .anon_sym_trace:
            self.logger.debug("Not implemented")
        case .anon_sym_read:
            self.logger.debug("Not implemented")
        case .anon_sym_read_QMARK:
            self.logger.debug("Not implemented")
        case .anon_sym_read_STAR:
            self.logger.debug("Not implemented")
        case .sym_lineComment:
            self.logger.debug("Not implemented")
        case .sym_docComment:
            self.logger.debug("Not implemented")
        case .sym_blockComment:
            self.logger.debug("Not implemented")
        case .sym__sl1_string_chars:
            self.logger.debug("Not implemented")
        case .sym__sl2_string_chars:
            self.logger.debug("Not implemented")
        case .sym__sl3_string_chars:
            self.logger.debug("Not implemented")
        case .sym__sl4_string_chars:
            self.logger.debug("Not implemented")
        case .sym__sl5_string_chars:
            self.logger.debug("Not implemented")
        case .sym__sl6_string_chars:
            self.logger.debug("Not implemented")
        case .sym__ml_string_chars:
            self.logger.debug("Not implemented")
        case .sym__ml1_string_chars:
            self.logger.debug("Not implemented")
        case .sym__ml2_string_chars:
            self.logger.debug("Not implemented")
        case .sym__ml3_string_chars:
            self.logger.debug("Not implemented")
        case .sym__ml4_string_chars:
            self.logger.debug("Not implemented")
        case .sym__ml5_string_chars:
            self.logger.debug("Not implemented")
        case .sym__ml6_string_chars:
            self.logger.debug("Not implemented")
        case .sym__open_square_bracket:
            self.logger.debug("Not implemented")
        case .sym__open_entry_bracket:
            self.logger.debug("Not implemented")
        case .sym_module:
            self.logger.debug("Starting building module...")
            var contents: [any ASTNode] = []
            node.enumerateChildren(block: { node in
                if let content = tsNodeToASTNode(node: node, in: document) {
                    contents.append(content)
                }
            })
            return PklModule(contents: contents, positionStart: node.pointRange.lowerBound.toPosition(), positionEnd: node.pointRange.upperBound.toPosition())
        case .sym_moduleHeader:
            self.logger.debug("Not implemented")
        case .sym_moduleClause:
            self.logger.debug("Not implemented")
        case .sym_extendsOrAmendsClause:
            self.logger.debug("Not implemented")
        case .sym_importClause:
            self.logger.debug("Not implemented")
        case .sym_importGlobClause:
            self.logger.debug("Not implemented")
        case .sym__moduleMember:
            self.logger.debug("Not implemented")

        case .sym_clazz: // CLASS DECLARATION
            self.logger.debug("Starting building class...")
            var classNode: PklClass?
            var classKeyword: String?
            var classIdentifier: String?
            node.enumerateChildren(block: { node in
                if node.symbol == PklTreeSitterSymbols.sym_classBody.rawValue {
                    classNode = tsNodeToASTNode(node: node, in: document) as? PklClass
                    return
                }
                if node.symbol == PklTreeSitterSymbols.sym_identifier.rawValue {
                    classIdentifier = document.getTextInByteRange(node.byteRange)
                    return
                }
                if node.symbol == PklTreeSitterSymbols.anon_sym_class.rawValue {
                    classKeyword = document.getTextInByteRange(node.byteRange)
                    return
                }
            })
            return PklClassDeclaration(classNode: classNode, classKeyword: classKeyword, classIdentifier: classIdentifier,
                positionStart: node.pointRange.lowerBound.toPosition(), positionEnd: node.pointRange.upperBound.toPosition())

        case .sym_classExtendsClause:
            self.logger.debug("Not implemented")

        case .sym_classBody:
            self.logger.debug("Starting building class body...")
            var properties: [PklClassProperty] = []
            var functions: [PklFunctionDeclaration] = []
            var leftBraceIsPresent: Bool = false
            var rightBraceIsPresent: Bool = false
            node.enumerateChildren(block: { node in
                if node.symbol == PklTreeSitterSymbols.sym_classProperty.rawValue {
                    if let property = tsNodeToASTNode(node: node, in: document) as? PklClassProperty {
                        properties.append(property)
                    }
                    return
                }
                if node.symbol == PklTreeSitterSymbols.sym_classMethod.rawValue {
                    if let function = tsNodeToASTNode(node: node, in: document) as? PklFunctionDeclaration {
                        functions.append(function)
                    }
                    return
                }
                if node.symbol == PklTreeSitterSymbols.anon_sym_LBRACE.rawValue {
                    leftBraceIsPresent = true
                    return
                }
                if node.symbol == PklTreeSitterSymbols.anon_sym_RBRACE.rawValue {
                    rightBraceIsPresent = true
                    return
                }
            })
            return PklClass(properties: properties, functions: functions, leftBraceIsPresent: leftBraceIsPresent, rightBraceIsPresent: rightBraceIsPresent,
                positionStart: node.pointRange.lowerBound.toPosition(), positionEnd: node.pointRange.upperBound.toPosition())

        case .sym_typeAlias:
            self.logger.debug("Not implemented")

        case .sym_classProperty:
            self.logger.debug("Starting building class property...")
            var propertyIdentifier: String?
            var typeAnnotation: PklTypeAnnotation?
            var value: PklValue?
            var isHidden: Bool = false
            node.enumerateChildren(block: { node in
                if node.symbol == PklTreeSitterSymbols.sym_identifier.rawValue {
                    propertyIdentifier = document.getTextInByteRange(node.byteRange)
                    return
                }
                if node.symbol == PklTreeSitterSymbols.sym_typeAnnotation.rawValue {
                    typeAnnotation = tsNodeToASTNode(node: node, in: document) as? PklTypeAnnotation
                    return
                }
                // TODO: parse value && type checking
                // TODO: parse isHidden
            })
            return PklClassProperty(identifier: propertyIdentifier, typeAnnotation: typeAnnotation, value: value, isHidden: isHidden,
                positionStart: node.pointRange.lowerBound.toPosition(), positionEnd: node.pointRange.upperBound.toPosition())

        case .sym_classMethod:
            self.logger.debug("Starting building class method...")
            var functionValue: (any ASTNode)?
            var body: PklClassFunctionBody?
            node.enumerateChildren(block: { node in
                if node.symbol == PklTreeSitterSymbols.sym_methodHeader.rawValue {
                    body = tsNodeToASTNode(node: node, in: document) as? PklClassFunctionBody
                    return
                }
                // TODO: parse function value && type checking
            })
            return PklFunctionDeclaration(body: body, functionValue: functionValue,
                positionStart: node.pointRange.lowerBound.toPosition(), positionEnd: node.pointRange.upperBound.toPosition())

        case .sym_methodHeader:
            self.logger.debug("Starting building method header...")
            var isFunctionKeywordPresent: Bool = false
            var identifier: String?
            var typeAnnotation: PklTypeAnnotation?
            var params: PklFunctionParameterList?
            node.enumerateChildren(block: { node in
                if node.symbol == PklTreeSitterSymbols.anon_sym_function.rawValue {
                    isFunctionKeywordPresent = true
                    return
                }
                if node.symbol == PklTreeSitterSymbols.sym_identifier.rawValue {
                    identifier = document.getTextInByteRange(node.byteRange)
                    return
                }
                if node.symbol == PklTreeSitterSymbols.sym_typeAnnotation.rawValue {
                    typeAnnotation = tsNodeToASTNode(node: node, in: document) as? PklTypeAnnotation
                    return
                }
                if node.symbol == PklTreeSitterSymbols.sym_parameterList.rawValue {
                    params = tsNodeToASTNode(node: node, in: document) as? PklFunctionParameterList
                    return
                }
            })
            return PklClassFunctionBody(isFunctionKeywordPresent: isFunctionKeywordPresent, identifier: identifier, params: params,
                positionStart: node.pointRange.upperBound.toPosition(), positionEnd: node.pointRange.lowerBound.toPosition())

        case .sym_annotation:
            self.logger.debug("Not implemented")
        case .sym_objectBody:
            self.logger.debug("Not implemented")
        case .sym__objectMember:
            self.logger.debug("Not implemented")
        case .sym_objectProperty:
            self.logger.debug("Not implemented")
        case .sym_objectMethod:
            self.logger.debug("Not implemented")
        case .sym_objectEntry:
            self.logger.debug("Not implemented")
        case .sym_objectElement:
            self.logger.debug("Not implemented")
        case .sym_objectPredicate:
            self.logger.debug("Not implemented")
        case .sym_forGenerator:
            self.logger.debug("Not implemented")
        case .sym_whenGenerator:
            self.logger.debug("Not implemented")
        case .sym_objectSpread:
            self.logger.debug("Not implemented")
        case .sym_objectBodyParameters:
            self.logger.debug("Not implemented")

        case .sym_typeAnnotation:
            self.logger.debug("Starting building type annotation...")
            var type: PklType?
            var colonIsPresent: Bool = false
            node.enumerateChildren(block: { node in
                if node.symbol == PklTreeSitterSymbols.anon_sym_COLON.rawValue {
                    colonIsPresent = true
                    return
                }
                if node.symbol == PklTreeSitterSymbols.sym_type.rawValue {
                    type = tsNodeToASTNode(node: node, in: document) as? PklType
                    return
                }
            })
            return PklTypeAnnotation(type: type, colonIsPresent: colonIsPresent, positionStart: node.pointRange.lowerBound.toPosition(),
                positionEnd: node.pointRange.upperBound.toPosition())

        case .sym_type:
            self.logger.debug("Starting building type...")
            let typeIdentifier = document.getTextInByteRange(node.byteRange)
            return PklType(identifier: typeIdentifier,
                positionStart: node.pointRange.lowerBound.toPosition(), positionEnd: node.pointRange.upperBound.toPosition())

        case .sym_typeArgumentList:
            self.logger.debug("Not implemented")
        case .sym_typeParameterList:
            self.logger.debug("Not implemented")
        case .sym_typeParameter:
            self.logger.debug("Not implemented")
        case .sym_parameterList:
            self.logger.debug("Starting building parameter list...")
            var parameters: [PklFunctionParameter] = []
            var leftParenIsPresent: Bool = false
            var rightParenIsPresent: Bool = false
            var commasAmount: Int = 0
            node.enumerateChildren(block: { node in
                if node.symbol == PklTreeSitterSymbols.anon_sym_LPAREN.rawValue {
                    leftParenIsPresent = true
                    return
                }
                if node.symbol == PklTreeSitterSymbols.anon_sym_RPAREN.rawValue {
                    rightParenIsPresent = true
                    return
                }
                if node.symbol == PklTreeSitterSymbols.anon_sym_COMMA.rawValue {
                    commasAmount += 1
                    return
                }
                if node.symbol == PklTreeSitterSymbols.sym_typedIdentifier.rawValue {
                    if let parameter = tsNodeToASTNode(node: node, in: document) as? PklFunctionParameter {
                        parameters.append(parameter)
                    }
                    return
                }
            })
            return PklFunctionParameterList(parameters: parameters, positionStart: node.pointRange.lowerBound.toPosition(), positionEnd: node.pointRange.upperBound.toPosition())

        case .sym_argumentList:
            self.logger.debug("Not implemented")
        case .sym_modifier:
            self.logger.debug("Not implemented")
        case .sym__expr:
            self.logger.debug("Not implemented")
        case .sym_variableObjectLiteral:
            self.logger.debug("Not implemented")
        case .sym__expr2:
            self.logger.debug("Not implemented")
        case .sym_parenthesizedExpr:
            self.logger.debug("Not implemented")
        case .sym_moduleExpr:
            self.logger.debug("Not implemented")
        case .sym_variableExpr:
            self.logger.debug("Not implemented")
        case .sym_stringConstant:
            self.logger.debug("Not implemented")
        case .sym_slStringLiteral:
            self.logger.debug("Not implemented")
        case .sym_mlStringLiteral:
            self.logger.debug("Not implemented")
        case .sym_interpolationExpr:
            self.logger.debug("Not implemented")
        case .sym_interpolationExpr1:
            self.logger.debug("Not implemented")
        case .sym_interpolationExpr2:
            self.logger.debug("Not implemented")
        case .sym_interpolationExpr3:
            self.logger.debug("Not implemented")
        case .sym_interpolationExpr4:
            self.logger.debug("Not implemented")
        case .sym_interpolationExpr5:
            self.logger.debug("Not implemented")
        case .sym_interpolationExpr6:
            self.logger.debug("Not implemented")
        case .sym_newExpr:
            self.logger.debug("Not implemented")
        case .sym_objectLiteral:
            self.logger.debug("Not implemented")
        case .sym_methodCallExpr:
            self.logger.debug("Not implemented")
        case .sym_propertyCallExpr:
            self.logger.debug("Not implemented")
        case .sym_subscriptExpr:
            self.logger.debug("Not implemented")
        case .sym_unaryExpr:
            self.logger.debug("Not implemented")
        case .sym_binaryExprRightAssoc:
            self.logger.debug("Not implemented")
        case .sym_binaryExpr:
            self.logger.debug("Not implemented")
        case .sym_isExpr:
            self.logger.debug("Not implemented")
        case .sym_asExpr:
            self.logger.debug("Not implemented")
        case .sym_ifExpr:
            self.logger.debug("Not implemented")
        case .sym_letExpr:
            self.logger.debug("Not implemented")
        case .sym_throwExpr:
            self.logger.debug("Not implemented")
        case .sym_traceExpr:
            self.logger.debug("Not implemented")
        case .sym_readExpr:
            self.logger.debug("Not implemented")
        case .sym_readOrNullExpr:
            self.logger.debug("Not implemented")
        case .sym_readGlobExpr:
            self.logger.debug("Not implemented")
        case .sym_importExpr:
            self.logger.debug("Not implemented")
        case .sym_importGlobExpr:
            self.logger.debug("Not implemented")
        case .sym_functionLiteral:
            self.logger.debug("Not implemented")
        case .sym_qualifiedIdentifier:
            self.logger.debug("Not implemented")

        case .sym_typedIdentifier:
            self.logger.debug("Starting building typed identifier...")
            var identifier: String?
            var typeAnnotation: PklTypeAnnotation?
            node.enumerateChildren(block: { node in
                if node.symbol == PklTreeSitterSymbols.sym_identifier.rawValue {
                    identifier = document.getTextInByteRange(node.byteRange)
                    return
                }
                if node.symbol == PklTreeSitterSymbols.sym_typeAnnotation.rawValue {
                    typeAnnotation = tsNodeToASTNode(node: node, in: document) as? PklTypeAnnotation
                    return
                }
            })
            return PklFunctionParameter(identifier: identifier, typeAnnotation: typeAnnotation,
                positionStart: node.pointRange.lowerBound.toPosition(), positionEnd: node.pointRange.upperBound.toPosition())

        case .aux_sym_module_repeat1:
            self.logger.debug("Not implemented")
        case .aux_sym_module_repeat2:
            self.logger.debug("Not implemented")
        case .aux_sym_moduleHeader_repeat1:
            self.logger.debug("Not implemented")
        case .aux_sym_moduleClause_repeat1:
            self.logger.debug("Not implemented")
        case .aux_sym_classBody_repeat1:
            self.logger.debug("Not implemented")
        case .aux_sym_classProperty_repeat1:
            self.logger.debug("Not implemented")
        case .aux_sym_objectBody_repeat1:
            self.logger.debug("Not implemented")
        case .aux_sym_objectBodyParameters_repeat1:
            self.logger.debug("Not implemented")
        case .aux_sym_type_repeat1:
            self.logger.debug("Not implemented")
        case .aux_sym_type_repeat2:
            self.logger.debug("Not implemented")
        case .aux_sym_typeParameterList_repeat1:
            self.logger.debug("Not implemented")
        case .aux_sym_stringConstant_repeat1:
            self.logger.debug("Not implemented")
        case .aux_sym_stringConstant_repeat2:
            self.logger.debug("Not implemented")
        case .aux_sym_slStringLiteral_repeat1:
            self.logger.debug("Not implemented")
        case .aux_sym_slStringLiteral_repeat2:
            self.logger.debug("Not implemented")
        case .aux_sym_slStringLiteral_repeat3:
            self.logger.debug("Not implemented")
        case .aux_sym_slStringLiteral_repeat4:
            self.logger.debug("Not implemented")
        case .aux_sym_slStringLiteral_repeat5:
            self.logger.debug("Not implemented")
        case .aux_sym_slStringLiteral_repeat6:
            self.logger.debug("Not implemented")
        case .aux_sym_slStringLiteral_repeat7:
            self.logger.debug("Not implemented")
        case .aux_sym_mlStringLiteral_repeat1:
            self.logger.debug("Not implemented")
        case .aux_sym_mlStringLiteral_repeat2:
            self.logger.debug("Not implemented")
        case .aux_sym_mlStringLiteral_repeat3:
            self.logger.debug("Not implemented")
        case .aux_sym_mlStringLiteral_repeat4:
            self.logger.debug("Not implemented")
        case .aux_sym_mlStringLiteral_repeat5:
            self.logger.debug("Not implemented")
        case .aux_sym_mlStringLiteral_repeat6:
            self.logger.debug("Not implemented")
        case .aux_sym_mlStringLiteral_repeat7:
            self.logger.debug("Not implemented")
        case .aux_sym_qualifiedIdentifier_repeat1:
            self.logger.debug("Not implemented")
        }
        return nil
    }

}

extension Point {
    public func toPosition() -> Position {
        return Position.init((Int(self.row), Int(self.column)))
    }
}

