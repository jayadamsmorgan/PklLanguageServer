import Foundation
import LanguageServerProtocol
import Logging
import SwiftTreeSitter
import TreeSitterPkl

public class TreeSitterParser {
    let logger: Logger

    let parser = Parser()
    var parsedTrees: [Document: MutableTree]
    var astParsedTrees: ThreadSafeDictionary<Document, any ASTNode>

    private var documentProvider: DocumentProvider?

    private var importedModules: [PklModuleImport] = []
    private var modulesQueue = BlockingQueue<ParseImportQueueElement>()

    private var variables: [Document: [PklVariable]] = [:]
    private var objectReferences: [Document: [any ASTNode]] = [:]

    let maxImportDepth: Int

    public func setDocumentProvider(_ documentProvider: DocumentProvider) {
        self.documentProvider = documentProvider
    }

    public init(logger: Logger, maxImportDepth: Int) {
        self.logger = logger
        let language = Language(language: tree_sitter_pkl())
        parsedTrees = [:]
        astParsedTrees = .init()
        self.maxImportDepth = maxImportDepth
        do {
            try parser.setLanguage(language)
        } catch {
            logger.debug("Failed to set language: \(error)")
            return
        }
        importQueue()
    }

    private func parseDocumentTreeSitterWithChanges(
        oldDocument: Document,
        newDocument: Document,
        previousParsingTree: MutableTree,
        changes _: [TextDocumentContentChangeEvent]
    ) async -> MutableTree? {
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

    public func parseDocumentTreeSitter(newDocument: Document, importDepth: Int = 0) async {
        guard let tree = parser.parse(newDocument.text) else {
            logger.error("Failed to tree-sitter parse complete source.")
            return
        }
        guard let rootNode = tree.rootNode else {
            logger.error("Failed to tree-sitter parse complete source. Root node is nil.")
            return
        }
        logger.debug("Document \(newDocument) parsed successfully. Tree: \(tree)")
        parsedTrees[newDocument] = tree
        if logger.logLevel == .debug || logger.logLevel == .trace {
            listTreeSitterNodes(rootNode: rootNode, document: newDocument)
        }
        guard let astParsing = await tsNodeToASTNode(node: rootNode, in: newDocument, importDepth: importDepth) else {
            logger.error("Failed to parse tree-sitter tree to AST tree.")
            return
        }
        if logger.logLevel == .debug || logger.logLevel == .trace {
            listASTNodes(rootNode: astParsing)
        }
        astParsedTrees.updateValue(astParsing, forKey: newDocument)
        guard let variables = variables[newDocument] else {
            logger.debug("No variables found for document \(newDocument.uri)")
            return
        }
        guard let references = objectReferences[newDocument] else {
            logger.debug("No references found for document \(newDocument.uri)")
            return
        }
        for variable in variables {
            variable.reference = references.first(where: { ref in
                if let ref = ref as? PklClassProperty {
                    if ref.identifier?.value == variable.identifier?.value {
                        return true
                    }
                }
                if let ref = ref as? PklObjectProperty {
                    if ref.identifier?.value == variable.identifier?.value {
                        return true
                    }
                }
                return false
            })
        }
    }

    public func parseDocumentTreeSitter(oldDocument: Document, newDocument: Document, changes: [TextDocumentContentChangeEvent]) async {
        if let previousParsingTree = parsedTrees[oldDocument] {
            if let tree = await parseDocumentTreeSitterWithChanges(
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
                guard let astParsing = await tsNodeToASTNode(node: rootNode, in: newDocument, importDepth: 0) else {
                    logger.error("Failed to parse tree-sitter tree to AST tree.")
                    return
                }
                if logger.logLevel == .debug || logger.logLevel == .trace {
                    listASTNodes(rootNode: astParsing)
                }
                astParsedTrees.updateValue(astParsing, forKey: newDocument)
                return
            }
            logger.debug("Failed to tree-sitter parse source with changes, trying to parse whole document...")
        }
        parsedTrees[oldDocument] = nil
        await parseDocumentTreeSitter(newDocument: newDocument)
    }

    // List tree sitter nodes used for debugging
    private func listTreeSitterNodes(rootNode: Node, depth: Int = 0, document: Document) {
        rootNode.enumerateChildren(block: { node in
            guard let treeSitterSymbol = PklTreeSitterSymbols(node.symbol) else {
                return
            }
            let text = document.getTextInByteRange(node.byteRange)
            logger.debug(
                "TS Node: \(treeSitterSymbol)," +
                    " depth: \(depth)," +
                    " range: \(node.pointRange)," +
                    " text: \(text)"
            )
            listTreeSitterNodes(rootNode: node, depth: depth + 1, document: document)
        })
    }

    private func listASTNodes(rootNode: any ASTNode, depth: Int = 0) {
        guard let children = rootNode.children else {
            return
        }
        for childNode in children {
            let text = childNode.document.getTextInByteRange(childNode.range.byteRange)
            logger.debug(
                "AST Node: \(type(of: childNode))," +
                    " depth: \(depth)," +
                    " range: \(childNode.range.positionRange)," +
                    " importDepth: \(childNode.importDepth)," +
                    " text: \(text)"
            )
            listASTNodes(rootNode: childNode, depth: depth + 1)
        }
    }

    private func importQueue() {
        Task {
            while true {
                let element = self.modulesQueue.dequeue()
                if element.importDepth > maxImportDepth || maxImportDepth == 0 {
                    self.logger.info("Import Queue: Import depth is too high. Skipping import for \(element.documentToBeImported).")
                    try await self.documentProvider?.provideDiagnostics(document: documentProvider?.openedDocument ?? element.importingDocument)
                    continue
                }
                var newParsedModule = self.astParsedTrees.value(forKey: element.documentToBeImported) as? PklModule
                if let newParsedModule {
                    let importingModule = self.astParsedTrees.waitForValue(forKey: element.importingDocument) as? PklModule
                    guard let importingModule else {
                        self.logger.error("Import Queue: Unable to find importing module.")
                        continue
                    }
                    let moduleImport = element.moduleImport
                    moduleImport.module = newParsedModule
                    importingModule.contents.append(moduleImport)
                    self.astParsedTrees.updateValue(importingModule, forKey: element.importingDocument)
                    self.logger.debug("Import Queue: Module imported from cache.")
                    try await self.documentProvider?.provideDiagnostics(document: documentProvider?.openedDocument ?? element.importingDocument)
                    continue
                }
                await self.parseDocumentTreeSitter(newDocument: element.documentToBeImported, importDepth: element.importDepth + 1)
                newParsedModule = self.astParsedTrees.value(forKey: element.documentToBeImported) as? PklModule
                guard let newParsedModule else {
                    logger.error("Import Queue: Unable to parse module.")
                    continue
                }
                var importingModule: PklModule?
                importingModule = self.astParsedTrees.value(forKey: element.importingDocument) as? PklModule
                guard let importingModule else {
                    logger.error("Import Queue: Unable to find importing module.")
                    continue
                }
                let moduleImport = element.moduleImport
                moduleImport.module = newParsedModule
                importingModule.contents.append(moduleImport)
                self.astParsedTrees.updateValue(importingModule, forKey: element.importingDocument)
                try await self.documentProvider?.provideDiagnostics(document: documentProvider?.openedDocument ?? element.importingDocument)
                self.logger.debug("Import Queue: Module imported.")
            }
        }
    }

    public func includeModule(relPath: String, currentDocument: Document) async -> Document? {
        if relPath.starts(with: "pkl:") { // STDLIB
            guard let name = relPath.split(separator: ":").last else {
                logger.debug("Module include: Unable to find stdlib \(relPath)")
                return nil
            }
            let key = "\(name).pkl"
            guard let text = Resources.stdlib[key] else {
                logger.debug("Module include: No stdlib available with name \(key)")
                return nil
            }
            let document = Document(uri: currentDocument.uri, version: nil, text: text)
            return document
        }
        // Relative local path
        var fileURL = URL(fileURLWithPath: currentDocument.uri)
        fileURL.deleteLastPathComponent()
        fileURL.appendPathComponent(relPath)
        fileURL.standardize()
        do {
            guard try fileURL.checkResourceIsReachable() else {
                logger.debug("Module include: Unable to include module: Module is not reachable.")
                return nil
            }
            logger.debug("Module include: fileURL: \(fileURL.absoluteURL)")
            guard let text = try? String(contentsOf: fileURL, encoding: .utf8) else {
                logger.error("Module include: file not found: \(fileURL)")
                return nil
            }
            let document = Document(uri: fileURL.absoluteString, version: nil, text: text)
            logger.debug("Module include: file found: \(fileURL.absoluteString)")
            return document
        } catch {
            logger.debug("Module include: Unable to check if resource is reachable: \(error)")
            return nil
        }
    }

    private func tsNodeToASTNode(node: Node, in document: Document, importDepth: Int) async -> (any ASTNode)? {
        guard let tsSymbol = PklTreeSitterSymbols(node.symbol) else {
            logger.debug("Unable to parse node with symbol \(node.symbol)")
            return nil
        }

        switch tsSymbol {
        case .sym_identifier:
            logger.debug("Starting building identifier...")
            let identifier = document.getTextInByteRange(node.byteRange)
            logger.debug("Identifier built successfully.")
            let range = ASTRange(pointRange: node.pointRange, byteRange: node.byteRange)
            return PklIdentifier(value: identifier, range: range, importDepth: importDepth, document: document)

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
            logger.debug("Null literal built successfully.")
            let range = ASTRange(pointRange: node.pointRange, byteRange: node.byteRange)
            return PklNullLiteral(range: range, importDepth: importDepth, document: document)

        case .sym_trueLiteral: // BOOLEAN LITERAL
            logger.debug("Boolean literal built successfully.")
            let range = ASTRange(pointRange: node.pointRange, byteRange: node.byteRange)
            return PklBooleanLiteral(value: true, range: range, importDepth: importDepth, document: document)

        case .sym_falseLiteral: // BOOLEAN LITERAL
            logger.debug("Boolean literal built successfully.")
            let range = ASTRange(pointRange: node.pointRange, byteRange: node.byteRange)
            return PklBooleanLiteral(value: false, range: range, importDepth: importDepth, document: document)

        case .sym_intLiteral: // INTEGER LITERAL
            logger.debug("Starting building integer literal...")
            let value = document.getTextInByteRange(node.byteRange)
            logger.debug("Integer literal built successfully.")
            let range = ASTRange(pointRange: node.pointRange, byteRange: node.byteRange)
            return PklNumberLiteral(value: value, type: .int, range: range, importDepth: importDepth, document: document)

        case .sym_floatLiteral: // FLOAT LITERAL
            logger.debug("Starting building float literal...")
            let value = document.getTextInByteRange(node.byteRange)
            logger.debug("Float literal built successfully.")
            let range = ASTRange(pointRange: node.pointRange, byteRange: node.byteRange)
            return PklNumberLiteral(value: value, type: .float, range: range, importDepth: importDepth, document: document)

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
            logger.debug("Starting building binary operator...")
            let type: PklBinaryOperatorType = .subtraction
            logger.debug("Binary operator built successfully.")
            let range = ASTRange(pointRange: node.pointRange, byteRange: node.byteRange)
            return PklBinaryOperator(type: type, range: range, importDepth: importDepth, document: document)

        case .anon_sym_BANG:
            logger.debug("Not implemented")

        case .anon_sym_STAR_STAR:
            logger.debug("Starting building binary operator...")
            let type: PklBinaryOperatorType = .exponentiation
            logger.debug("Binary operator built successfully.")
            let range = ASTRange(pointRange: node.pointRange, byteRange: node.byteRange)
            return PklBinaryOperator(type: type, range: range, importDepth: importDepth, document: document)

        case .anon_sym_QMARK_QMARK:
            logger.debug("Not implemented")

        case .anon_sym_SLASH:
            logger.debug("Starting building binary operator...")
            let type: PklBinaryOperatorType = .division
            logger.debug("Binary operator built successfully.")
            let range = ASTRange(pointRange: node.pointRange, byteRange: node.byteRange)
            return PklBinaryOperator(type: type, range: range, importDepth: importDepth, document: document)

        case .anon_sym_TILDE_SLASH:
            logger.debug("Not implemented")

        case .anon_sym_PERCENT:
            logger.debug("Starting building binary operator...")
            let type: PklBinaryOperatorType = .modulus
            logger.debug("Binary operator built successfully.")
            let range = ASTRange(pointRange: node.pointRange, byteRange: node.byteRange)
            return PklBinaryOperator(type: type, range: range, importDepth: importDepth, document: document)

        case .anon_sym_PLUS:
            logger.debug("Starting building binary operator...")
            let type: PklBinaryOperatorType = .addition
            logger.debug("Binary operator built successfully.")
            let range = ASTRange(pointRange: node.pointRange, byteRange: node.byteRange)
            return PklBinaryOperator(type: type, range: range, importDepth: importDepth, document: document)

        case .anon_sym_LT_EQ:
            logger.debug("Starting building binary operator...")
            let type: PklBinaryOperatorType = .lessOrEquals
            logger.debug("Binary operator built successfully.")
            let range = ASTRange(pointRange: node.pointRange, byteRange: node.byteRange)
            return PklBinaryOperator(type: type, range: range, importDepth: importDepth, document: document)

        case .anon_sym_GT_EQ:
            logger.debug("Starting building binary operator...")
            let type: PklBinaryOperatorType = .greaterOrEquals
            logger.debug("Binary operator built successfully.")
            let range = ASTRange(pointRange: node.pointRange, byteRange: node.byteRange)
            return PklBinaryOperator(type: type, range: range, importDepth: importDepth, document: document)

        case .anon_sym_EQ_EQ:
            logger.debug("Starting building binary operator...")
            let type: PklBinaryOperatorType = .equals
            logger.debug("Binary operator built successfully.")
            let range = ASTRange(pointRange: node.pointRange, byteRange: node.byteRange)
            return PklBinaryOperator(type: type, range: range, importDepth: importDepth, document: document)

        case .anon_sym_BANG_EQ:
            logger.debug("Starting building binary operator...")
            let type: PklBinaryOperatorType = .notEquals
            logger.debug("Binary operator built successfully.")
            let range = ASTRange(pointRange: node.pointRange, byteRange: node.byteRange)
            return PklBinaryOperator(type: type, range: range, importDepth: importDepth, document: document)

        case .anon_sym_AMP_AMP:
            logger.debug("Starting building binary operator...")
            let type: PklBinaryOperatorType = .and
            logger.debug("Binary operator built successfully.")
            let range = ASTRange(pointRange: node.pointRange, byteRange: node.byteRange)
            return PklBinaryOperator(type: type, range: range, importDepth: importDepth, document: document)

        case .anon_sym_PIPE_PIPE:
            logger.debug("Starting building binary operator...")
            let type: PklBinaryOperatorType = .or
            logger.debug("Binary operator built successfully.")
            let range = ASTRange(pointRange: node.pointRange, byteRange: node.byteRange)
            return PklBinaryOperator(type: type, range: range, importDepth: importDepth, document: document)

        case .anon_sym_PIPE_GT:
            logger.debug("Not implemented")

        case .anon_sym_is:
            logger.debug("Starting building binary operator...")
            let type: PklBinaryOperatorType = .is
            logger.debug("Binary operator built successfully.")
            let range = ASTRange(pointRange: node.pointRange, byteRange: node.byteRange)
            return PklBinaryOperator(type: type, range: range, importDepth: importDepth, document: document)

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
            logger.debug("Line comment at \(node.pointRange).")

        case .sym_docComment:
            logger.debug("Not implemented")

        case .sym_blockComment:
            logger.debug("Block comment at \(node.pointRange)")

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
            for childPosition in 0 ..< node.childCount {
                guard let childNode = node.child(at: childPosition) else {
                    continue
                }
                if let astNode = await tsNodeToASTNode(node: childNode, in: document, importDepth: importDepth) {
                    contents.append(astNode)
                }
            }
            let range = ASTRange(pointRange: node.pointRange, byteRange: node.byteRange)
            let module = PklModule(contents: contents, range: range, importDepth: importDepth, document: document)
            if let errors = module.diagnosticErrors() {
                for error in errors {
                    logger.debug("AST Diagnostic error: \(error)")
                }
            }
            logger.debug("Module built successfully.")
            return module

        case .sym_moduleHeader:
            logger.debug("Starting building module header...")
            var moduleClause: PklModuleClause?
            var extendsOrAmends: PklModuleImport?
            for childPosition in 0 ..< node.childCount {
                guard let childNode = node.child(at: childPosition) else {
                    continue
                }
                if childNode.symbol == PklTreeSitterSymbols.sym_moduleClause.rawValue {
                    moduleClause = await tsNodeToASTNode(node: childNode, in: document, importDepth: importDepth) as? PklModuleClause
                }
                if childNode.symbol == PklTreeSitterSymbols.sym_extendsOrAmendsClause.rawValue {
                    extendsOrAmends = await tsNodeToASTNode(node: childNode, in: document, importDepth: importDepth) as? PklModuleImport
                }
            }
            let range = ASTRange(pointRange: node.pointRange, byteRange: node.byteRange)
            logger.debug("Module header built successfully.")
            return PklModuleHeader(moduleClause: moduleClause, extendsOrAmends: extendsOrAmends, range: range, importDepth: importDepth, document: document)

        case .sym_moduleClause:
            logger.debug("Starting building module clause...")
            var name: PklIdentifier?
            for childPosition in 0 ..< node.childCount {
                guard let childNode = node.child(at: childPosition) else {
                    continue
                }
                if childNode.symbol == PklTreeSitterSymbols.sym_qualifiedIdentifier.rawValue {
                    name = await tsNodeToASTNode(node: childNode, in: document, importDepth: importDepth) as? PklIdentifier
                }
            }
            let range = ASTRange(pointRange: node.pointRange, byteRange: node.byteRange)
            let moduleClause = PklModuleClause(name: name, range: range, importDepth: importDepth, document: document)
            var objectReferences = objectReferences[document] ?? []
            objectReferences.append(moduleClause)
            self.objectReferences[document] = objectReferences
            logger.debug("Module clause built successfully.")
            return moduleClause

        case .sym_extendsOrAmendsClause:
            logger.debug("Building extends or amends clause...")
            var amends = false
            var extends = false
            var path: PklStringLiteral?
            for childPosition in 0 ..< node.childCount {
                guard let childNode = node.child(at: childPosition) else {
                    continue
                }
                if childNode.symbol == PklTreeSitterSymbols.anon_sym_extends.rawValue {
                    logger.debug("Extends clause found.")
                    extends = true
                } else if childNode.symbol == PklTreeSitterSymbols.anon_sym_amends.rawValue {
                    logger.debug("Amends clause found.")
                    amends = true
                } else if childNode.symbol == PklTreeSitterSymbols.sym_stringConstant.rawValue {
                    path = await tsNodeToASTNode(node: childNode, in: document, importDepth: importDepth) as? PklStringLiteral
                    logger.debug("Path found: \(path?.value ?? "nil")")
                }
            }
            guard let path else {
                logger.error("Failed to parse path in extends or amends clause.")
                return nil
            }
            path.type = .importString
            guard var pathValue = path.value else {
                logger.error("Failed to parse path in extends or amends clause.")
                return nil
            }
            pathValue.removeAll(where: { $0 == "\"" })
            logger.debug("Extends: \(extends), Amends: \(amends), Path: \(pathValue)")
            let type: PklModuleImportType = amends ? .amending : extends ? .extending : .error
            let range = ASTRange(pointRange: node.pointRange, byteRange: node.byteRange)
            let module = PklModuleImport(module: nil, range: range, path: path,
                                         importDepth: importDepth, document: document, type: type, exists: false)
            guard let importDocument = await includeModule(relPath: pathValue, currentDocument: document) else {
                logger.error("Failed to include module \(pathValue) in \(document.uri).")
                importedModules.append(module)
                return module
            }
            module.exists = true
            let parseQueueElement = ParseImportQueueElement(importDepth: importDepth, importingDocument: document, documentToBeImported: importDocument,
                                                      importType: type, moduleImport: module)
            modulesQueue.enqueue(parseQueueElement)
            logger.debug("Extends or amends clause built successfully.")
            return module

        case .sym_importClause: // IMPORT CLAUSE
            logger.debug("Starting building import clause...")
            if importDepth > 3 {
                logger.error("Import depth is too high.")
                return nil
            }
            var path: PklStringLiteral?
            for childPosition in 0 ..< node.childCount {
                guard let childNode = node.child(at: childPosition) else {
                    continue
                }
                if childNode.symbol == PklTreeSitterSymbols.sym_stringConstant.rawValue {
                    path = await tsNodeToASTNode(node: childNode, in: document, importDepth: importDepth) as? PklStringLiteral
                }
            }
            let range = ASTRange(pointRange: node.pointRange, byteRange: node.byteRange)
            let type: PklModuleImportType = .normal
            guard let path else {
                logger.error("Failed to parse path in import clause.")
                return nil
            }
            path.type = .importString
            guard var pathValue = path.value else {
                logger.error("Failed to parse path in import clause.")
                return nil
            }
            pathValue.removeAll(where: { $0 == "\"" })
            logger.debug("Path: \(pathValue)")
            let moduleImport = PklModuleImport(module: nil, range: range, path: path,
                                               importDepth: importDepth, document: document, type: type, exists: false)
            guard let importDocument = await includeModule(relPath: pathValue, currentDocument: document) else {
                logger.error("Failed to include module \(pathValue) in \(document.uri).")
                importedModules.append(moduleImport)
                return moduleImport
            }
            moduleImport.exists = true
            let parseQueueElement = ParseImportQueueElement(importDepth: importDepth, importingDocument: document,
                                                      documentToBeImported: importDocument, importType: type, moduleImport: moduleImport)
            modulesQueue.enqueue(parseQueueElement)
            return moduleImport

        case .sym_importGlobClause:
            logger.debug("Not implemented")
        case .sym__moduleMember:
            logger.debug("Not implemented")

        case .sym_clazz: // CLASS DECLARATION
            logger.debug("Starting building class...")
            var classNode: PklClass?
            var classKeyword: String?
            var classIdentifier: PklIdentifier?
            for childPosition in 0 ..< node.childCount {
                guard let childNode = node.child(at: childPosition) else {
                    continue
                }
                if childNode.symbol == PklTreeSitterSymbols.sym_classBody.rawValue {
                    classNode = await tsNodeToASTNode(node: childNode, in: document, importDepth: importDepth) as? PklClass
                    continue
                }
                if childNode.symbol == PklTreeSitterSymbols.sym_identifier.rawValue {
                    classIdentifier = await tsNodeToASTNode(node: childNode, in: document, importDepth: importDepth) as? PklIdentifier
                    continue
                }
                if childNode.symbol == PklTreeSitterSymbols.anon_sym_class.rawValue {
                    classKeyword = document.getTextInByteRange(childNode.byteRange)
                    continue
                }
            }
            logger.debug("Class built successfully.")
            let range = ASTRange(pointRange: node.pointRange, byteRange: node.byteRange)
            let classDeclaration = PklClassDeclaration(classNode: classNode, classKeyword: classKeyword, classIdentifier: classIdentifier, range: range, importDepth: importDepth, document: document)
            var objectReferences = objectReferences[document] ?? []
            objectReferences.append(classDeclaration)
            self.objectReferences[document] = objectReferences
            return classDeclaration

        case .sym_classExtendsClause:
            logger.debug("Not implemented")

        case .sym_classBody: // CLASS BODY
            logger.debug("Starting building class body...")
            var properties: [PklClassProperty] = []
            var functions: [PklFunctionDeclaration] = []
            var leftBraceIsPresent = false
            var rightBraceIsPresent = false
            for childPosition in 0 ..< node.childCount {
                guard let childNode = node.child(at: childPosition) else {
                    continue
                }
                if childNode.symbol == PklTreeSitterSymbols.sym_classProperty.rawValue {
                    if let property = await tsNodeToASTNode(node: childNode, in: document, importDepth: importDepth) as? PklClassProperty {
                        properties.append(property)
                    }
                    continue
                }
                if childNode.symbol == PklTreeSitterSymbols.sym_classMethod.rawValue {
                    if let function = await tsNodeToASTNode(node: childNode, in: document, importDepth: importDepth) as? PklFunctionDeclaration {
                        functions.append(function)
                    }
                    continue
                }
                if childNode.symbol == PklTreeSitterSymbols.anon_sym_LBRACE.rawValue {
                    let brace = document.getTextInByteRange(childNode.byteRange)
                    if brace == "{" {
                        leftBraceIsPresent = true
                    }
                    continue
                }
                if childNode.symbol == PklTreeSitterSymbols.anon_sym_RBRACE.rawValue {
                    let brace = document.getTextInByteRange(childNode.byteRange)
                    if brace == "}" {
                        rightBraceIsPresent = true
                    }
                    continue
                }
            }
            logger.debug("Class body built successfully.")
            let range = ASTRange(pointRange: node.pointRange, byteRange: node.byteRange)
            return PklClass(properties: properties, functions: functions,
                            leftBraceIsPresent: leftBraceIsPresent, rightBraceIsPresent: rightBraceIsPresent, range: range, importDepth: importDepth, document: document)

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
            var isLocal = false
            var isEqualsPresent = false
            for childPosition in 0 ..< node.childCount {
                guard let childNode = node.child(at: childPosition) else {
                    continue
                }
                if childNode.symbol == PklTreeSitterSymbols.sym_identifier.rawValue {
                    propertyIdentifier = await tsNodeToASTNode(node: childNode, in: document, importDepth: importDepth) as? PklIdentifier
                    continue
                }
                if childNode.symbol == PklTreeSitterSymbols.sym_typeAnnotation.rawValue {
                    typeAnnotation = await tsNodeToASTNode(node: childNode, in: document, importDepth: importDepth) as? PklTypeAnnotation
                    continue
                }
                if childNode.symbol == PklTreeSitterSymbols.sym_objectBody.rawValue {
                    value = await tsNodeToASTNode(node: childNode, in: document, importDepth: importDepth)
                    continue
                }
                if childNode.symbol == PklTreeSitterSymbols.anon_sym_EQ.rawValue {
                    isEqualsPresent = true
                    continue
                }
                if childNode.symbol == PklTreeSitterSymbols.anon_sym_hidden.rawValue {
                    isHidden = true
                    continue
                }
                if childNode.symbol == PklTreeSitterSymbols.anon_sym_local.rawValue {
                    isLocal = true
                    continue
                }
                value = await tsNodeToASTNode(node: childNode, in: document, importDepth: importDepth)
            }
            logger.debug("Class property built successfully.")
            let range = ASTRange(pointRange: node.pointRange, byteRange: node.byteRange)
            let classProperty = PklClassProperty(identifier: propertyIdentifier, typeAnnotation: typeAnnotation, isEqualsPresent: isEqualsPresent,
                                                 value: value, isHidden: isHidden, isLocal: isLocal, range: range, importDepth: importDepth, document: document)
            var objectReferences = objectReferences[document] ?? []
            objectReferences.append(classProperty)
            self.objectReferences[document] = objectReferences
            return classProperty

        case .sym_classMethod:
            logger.debug("Starting building class method...")
            var functionValue: (any ASTNode)?
            var body: PklClassFunctionBody?
            for childPosition in 0 ..< node.childCount {
                guard let childNode = node.child(at: childPosition) else {
                    continue
                }
                if childNode.symbol == PklTreeSitterSymbols.sym_methodHeader.rawValue {
                    body = await tsNodeToASTNode(node: childNode, in: document, importDepth: importDepth) as? PklClassFunctionBody
                    continue
                }
                functionValue = await tsNodeToASTNode(node: childNode, in: document, importDepth: importDepth)
            }
            logger.debug("Class method built successfully.")
            let range = ASTRange(pointRange: node.pointRange, byteRange: node.byteRange)
            let functionDeclaration = PklFunctionDeclaration(body: body, functionValue: functionValue, range: range, importDepth: importDepth, document: document)
            var objectReferences = objectReferences[document] ?? []
            objectReferences.append(functionDeclaration)
            self.objectReferences[document] = objectReferences
            return functionDeclaration

        case .sym_methodHeader: // METHOD HEADER
            logger.debug("Starting building method header...")
            var isFunctionKeywordPresent = false
            var identifier: PklIdentifier?
            var typeAnnotation: PklTypeAnnotation?
            var params: PklFunctionParameterList?
            for childPosition in 0 ..< node.childCount {
                guard let childNode = node.child(at: childPosition) else {
                    continue
                }
                if childNode.symbol == PklTreeSitterSymbols.anon_sym_function.rawValue {
                    isFunctionKeywordPresent = true
                    continue
                }
                if childNode.symbol == PklTreeSitterSymbols.sym_identifier.rawValue {
                    identifier = await tsNodeToASTNode(node: childNode, in: document, importDepth: importDepth) as? PklIdentifier
                    continue
                }
                if childNode.symbol == PklTreeSitterSymbols.sym_typeAnnotation.rawValue {
                    typeAnnotation = await tsNodeToASTNode(node: childNode, in: document, importDepth: importDepth) as? PklTypeAnnotation
                    continue
                }
                if childNode.symbol == PklTreeSitterSymbols.sym_parameterList.rawValue {
                    params = await tsNodeToASTNode(node: childNode, in: document, importDepth: importDepth) as? PklFunctionParameterList
                    continue
                }
            }
            logger.debug("Method header built successfully.")
            let range = ASTRange(pointRange: node.pointRange, byteRange: node.byteRange)
            return PklClassFunctionBody(isFunctionKeywordPresent: isFunctionKeywordPresent, identifier: identifier,
                                        params: params, typeAnnotation: typeAnnotation, range: range, importDepth: importDepth, document: document)

        case .sym_annotation:
            logger.debug("Not implemented")

        case .sym_objectBody: // OBJECT BODY
            logger.debug("Starting building object body...")
            var objectProperties: [PklObjectProperty] = []
            var objectEntries: [PklObjectEntry] = []
            var leftBraceIsPresent = false
            var rightBraceIsPresent = false
            for childPosition in 0 ..< node.childCount {
                guard let childNode = node.child(at: childPosition) else {
                    continue
                }
                if childNode.symbol == PklTreeSitterSymbols.sym_objectProperty.rawValue {
                    if let property = await tsNodeToASTNode(node: childNode, in: document, importDepth: importDepth) as? PklObjectProperty {
                        objectProperties.append(property)
                    }
                    continue
                }
                if childNode.symbol == PklTreeSitterSymbols.anon_sym_LBRACE.rawValue {
                    let brace = document.getTextInByteRange(childNode.byteRange)
                    if brace == "{" {
                        leftBraceIsPresent = true
                    }
                    continue
                }
                if childNode.symbol == PklTreeSitterSymbols.anon_sym_RBRACE.rawValue {
                    let brace = document.getTextInByteRange(childNode.byteRange)
                    if brace == "}" {
                        rightBraceIsPresent = true
                    }
                    continue
                }
                if childNode.symbol == PklTreeSitterSymbols.sym_objectEntry.rawValue {
                    if let property = await tsNodeToASTNode(node: childNode, in: document, importDepth: importDepth) as? PklObjectEntry {
                        objectEntries.append(property)
                    }
                    continue
                }
            }
            logger.debug("Object body built successfully.")
            let range = ASTRange(pointRange: node.pointRange, byteRange: node.byteRange)
            return PklObjectBody(objectProperties: objectProperties, objectEntries: objectEntries,
                                 isLeftBracePresent: leftBraceIsPresent, isRightBracePresent: rightBraceIsPresent, range: range, importDepth: importDepth, document: document)

        case .sym__objectMember:
            logger.debug("Not implemented")

        case .sym_objectProperty: // OBJECT PROPERTY
            logger.debug("Starting building object property...")
            var identifier: PklIdentifier?
            var typeAnnotation: PklTypeAnnotation?
            var value: (any ASTNode)?
            var isEqualsPresent = false
            for childPosition in 0 ..< node.childCount {
                guard let childNode = node.child(at: childPosition) else {
                    continue
                }
                if childNode.symbol == PklTreeSitterSymbols.sym_identifier.rawValue {
                    identifier = await tsNodeToASTNode(node: childNode, in: document, importDepth: importDepth) as? PklIdentifier
                    continue
                }
                if childNode.symbol == PklTreeSitterSymbols.sym_typeAnnotation.rawValue {
                    typeAnnotation = await tsNodeToASTNode(node: childNode, in: document, importDepth: importDepth) as? PklTypeAnnotation
                    continue
                }
                if childNode.symbol == PklTreeSitterSymbols.sym_objectBody.rawValue {
                    value = await tsNodeToASTNode(node: childNode, in: document, importDepth: importDepth)
                    continue
                }
                if childNode.symbol == PklTreeSitterSymbols.anon_sym_EQ.rawValue {
                    isEqualsPresent = true
                    continue
                }
                value = await tsNodeToASTNode(node: childNode, in: document, importDepth: importDepth)
            }
            logger.debug("Object property built successfully.")
            let range = ASTRange(pointRange: node.pointRange, byteRange: node.byteRange)
            let objectProperty = PklObjectProperty(identifier: identifier, typeAnnotation: typeAnnotation,
                                                   isEqualsPresent: isEqualsPresent, value: value, range: range, importDepth: importDepth, document: document)
            var objectReferences = objectReferences[document] ?? []
            objectReferences.append(objectProperty)
            self.objectReferences[document] = objectReferences
            return objectProperty

        case .sym_objectMethod:
            logger.debug("Not implemented")

        case .sym_objectEntry: // OBJECT ENTRY
            logger.debug("Starting building object entry...")
            var strIdentifier: PklStringLiteral?
            var value: (any ASTNode)?
            var isRightBracketPresent = false
            var isLeftBracketPresent = false
            var isEqualsPresent = false
            for childPosition in 0 ..< node.childCount {
                guard let childNode = node.child(at: childPosition) else {
                    continue
                }
                if childNode.symbol == PklTreeSitterSymbols.anon_sym_RBRACK.rawValue {
                    isRightBracketPresent = true
                } else if childNode.symbol == PklTreeSitterSymbols.sym__open_square_bracket.rawValue {
                    isLeftBracketPresent = true
                } else if childNode.symbol == PklTreeSitterSymbols.sym_slStringLiteral.rawValue {
                    strIdentifier = await tsNodeToASTNode(node: childNode, in: document, importDepth: importDepth) as? PklStringLiteral
                } else if childNode.symbol == PklTreeSitterSymbols.anon_sym_EQ.rawValue {
                    isEqualsPresent = true
                } else {
                    value = await tsNodeToASTNode(node: childNode, in: document, importDepth: importDepth)
                }
            }
            logger.debug("Object entry built successfully.")
            let range = ASTRange(pointRange: node.pointRange, byteRange: node.byteRange)
            let objectEntry = PklObjectEntry(strIdentifier: strIdentifier, value: value, isEqualsPresent: isEqualsPresent,
                                             isLeftBracketPresent: isLeftBracketPresent, isRightBracketPresent: isRightBracketPresent, range: range, importDepth: importDepth, document: document)
            var objectReferences = objectReferences[document] ?? []
            objectReferences.append(objectEntry)
            self.objectReferences[document] = objectReferences
            return objectEntry

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
            for childPosition in 0 ..< node.childCount {
                guard let childNode = node.child(at: childPosition) else {
                    continue
                }
                if childNode.symbol == PklTreeSitterSymbols.anon_sym_COLON.rawValue {
                    colonIsPresent = true
                    continue
                }
                if childNode.symbol == PklTreeSitterSymbols.sym_type.rawValue {
                    type = await tsNodeToASTNode(node: childNode, in: document, importDepth: importDepth) as? PklType
                    continue
                }
            }
            logger.debug("Type annotation built successfully.")
            let range = ASTRange(pointRange: node.pointRange, byteRange: node.byteRange)
            return PklTypeAnnotation(type: type, colonIsPresent: colonIsPresent, range: range, importDepth: importDepth, document: document)

        case .sym_type: // TYPE
            logger.debug("Starting building type...")
            let typeIdentifier = document.getTextInByteRange(node.byteRange)
            logger.debug("Type built successfully.")
            let range = ASTRange(pointRange: node.pointRange, byteRange: node.byteRange)
            return PklType(identifier: typeIdentifier, range: range, importDepth: importDepth, document: document)

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
            for childPosition in 0 ..< node.childCount {
                guard let childNode = node.child(at: childPosition) else {
                    continue
                }
                if childNode.symbol == PklTreeSitterSymbols.anon_sym_LPAREN.rawValue {
                    let leftParen = document.getTextInByteRange(childNode.byteRange)
                    if leftParen == "(" {
                        leftParenIsPresent = true
                    }
                    continue
                }
                if childNode.symbol == PklTreeSitterSymbols.anon_sym_RPAREN.rawValue {
                    let rightParen = document.getTextInByteRange(childNode.byteRange)
                    if rightParen == ")" {
                        rightParenIsPresent = true
                    }
                    continue
                }
                if childNode.symbol == PklTreeSitterSymbols.anon_sym_COMMA.rawValue {
                    commasAmount += 1
                    continue
                }
                if childNode.symbol == PklTreeSitterSymbols.sym_typedIdentifier.rawValue {
                    if let parameter = await tsNodeToASTNode(node: childNode, in: document, importDepth: importDepth) as? PklFunctionParameter {
                        parameters.append(parameter)
                    }
                }
            }
            logger.debug("Parameter list built successfully.")
            let range = ASTRange(pointRange: node.pointRange, byteRange: node.byteRange)
            return PklFunctionParameterList(parameters: parameters, isLeftParenPresent: leftParenIsPresent,
                                            isRightParenPresent: rightParenIsPresent, range: range, importDepth: importDepth, document: document)

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
            logger.debug("Starting building variable expression...")
            var identifier: PklIdentifier?
            for childPosition in 0 ..< node.childCount {
                guard let childNode = node.child(at: childPosition) else {
                    continue
                }
                if childNode.symbol == PklTreeSitterSymbols.sym_identifier.rawValue {
                    identifier = await tsNodeToASTNode(node: childNode, in: document, importDepth: importDepth) as? PklIdentifier
                }
            }
            let range = ASTRange(pointRange: node.pointRange, byteRange: node.byteRange)
            guard let identifier else {
                logger.error("Error building variable expression: Identifier is nil.")
                return PklVariable(identifier: nil, reference: nil, range: range, importDepth: importDepth, document: document)
            }
            let variable = PklVariable(identifier: identifier, reference: nil, range: range, importDepth: importDepth, document: document)
            var vars = variables[document] ?? []
            vars.append(variable)
            variables[document] = vars
            return variable

        case .sym_stringConstant: // STRING CONSTANT
            logger.debug("Starting building string constant...")
            let value: String? = document.getTextInByteRange(node.byteRange)
            logger.debug("String constant built successfully.")
            let range = ASTRange(pointRange: node.pointRange, byteRange: node.byteRange)
            return PklStringLiteral(value: value, type: .constant, range: range, importDepth: importDepth, document: document)

        case .sym_slStringLiteral: // SINGLE-LINE STRING LITERAL
            logger.debug("Starting building single-line string literal...")
            let value: String? = document.getTextInByteRange(node.byteRange)
            logger.debug("Single-line string literal built successfully.")
            let range = ASTRange(pointRange: node.pointRange, byteRange: node.byteRange)
            return PklStringLiteral(value: value, type: .singleLine, range: range, importDepth: importDepth, document: document)

        case .sym_mlStringLiteral: // MULTI-LINE STRING LITERAL
            logger.debug("Starting building multi-line string literal...")
            let value: String? = document.getTextInByteRange(node.byteRange)
            logger.debug("Multi-line string literal built successfully.")
            let range = ASTRange(pointRange: node.pointRange, byteRange: node.byteRange)
            return PklStringLiteral(value: value, type: .multiLine, range: range, importDepth: importDepth, document: document)

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
            var nestedMethodCalls = 0
            for childPosition in 0 ..< node.childCount {
                guard let childNode = node.child(at: childPosition) else {
                    continue
                }
                if childNode.symbol == PklTreeSitterSymbols.sym_methodCallExpr.rawValue {
                    nestedMethodCalls += 1
                }
            }
            let range = ASTRange(pointRange: node.pointRange, byteRange: node.byteRange)
            guard nestedMethodCalls == 0 else {
                logger.debug("Starting building nested method call expression...")
                let nestedMethodCallExpr = PklNestedMethodCallExpression(methodCalls: [], tail: [], range: range, importDepth: importDepth, document: document)
                for childPosition in 0 ..< node.childCount {
                    guard let childNode = node.child(at: childPosition) else {
                        continue
                    }
                    if childNode.symbol == PklTreeSitterSymbols.sym_methodCallExpr.rawValue {
                        if let methodCall = await tsNodeToASTNode(node: childNode, in: document, importDepth: importDepth) as? PklMethodCallExpression {
                            nestedMethodCallExpr.methodCalls.append(methodCall)
                        }
                    } else {
                        if let child = await tsNodeToASTNode(node: childNode, in: document, importDepth: importDepth) {
                            nestedMethodCallExpr.tail?.append(child)
                        }
                    }
                }
                logger.debug("Nested method call expression built successfully.")
                return nestedMethodCallExpr
            }
            logger.debug("Starting building standard method call expression...")
            var identifier: PklIdentifier?
            var variables: [PklVariable] = []
            var dotCount = 0
            var params: PklMethodParameterList?
            for childPosition in 0 ..< node.childCount {
                guard let childNode = node.child(at: childPosition) else {
                    continue
                }
                if childNode.symbol == PklTreeSitterSymbols.sym_identifier.rawValue {
                    identifier = await tsNodeToASTNode(node: childNode, in: document, importDepth: importDepth) as? PklIdentifier
                    continue
                }
                if childNode.symbol == PklTreeSitterSymbols.anon_sym_DOT.rawValue {
                    dotCount += 1
                    continue
                }
                if childNode.symbol == PklTreeSitterSymbols.sym_variableExpr.rawValue {
                    if let variable = await tsNodeToASTNode(node: childNode, in: document, importDepth: importDepth) as? PklVariable {
                        variables.append(variable)
                    }
                    continue
                }
                if childNode.symbol == PklTreeSitterSymbols.sym_parameterList.rawValue {
                    params = await tsNodeToASTNode(node: childNode, in: document, importDepth: importDepth) as? PklMethodParameterList
                    continue
                }
            }
            let methodCallExpr = PklMethodCallExpression(identifier: identifier, variableCalls: variables,
                                                         params: params, range: range, importDepth: importDepth, document: document)
            logger.debug("Method Call Expression built successfully")
            return methodCallExpr

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

        case .sym_importExpr: // IMPORT EXPRESSION
            logger.debug("Starting building import expression...")
            var path: PklStringLiteral?
            for childPosition in 0 ..< node.childCount {
                guard let childNode = node.child(at: childPosition) else {
                    continue
                }
                if childNode.symbol == PklTreeSitterSymbols.sym_stringConstant.rawValue {
                    path = await tsNodeToASTNode(node: childNode, in: document, importDepth: importDepth) as? PklStringLiteral
                    continue
                }
            }
            logger.debug("Import expression built successfully.")
            let range = ASTRange(pointRange: node.pointRange, byteRange: node.byteRange)
            guard let path else {
                logger.error("Failed to parse path in import expression.")
                return nil
            }
            path.type = .importString
            guard var pathValue = path.value else {
                logger.error("Failed to parse path in import clause.")
                return nil
            }
            pathValue.removeAll(where: { $0 == "\"" })
            logger.debug("Path: \(pathValue)")
            let moduleImport = PklModuleImport(module: nil, range: range, path: path, importDepth: importDepth, document: document, type: .normal, exists: false)
            guard let importDocument = await includeModule(relPath: pathValue, currentDocument: document) else {
                logger.error("Failed to include module \(pathValue) in \(document.uri).")
                importedModules.append(moduleImport)
                return moduleImport
            }
            moduleImport.exists = true
            let parseQueueElement = ParseImportQueueElement(importDepth: importDepth, importingDocument: document,
                documentToBeImported: importDocument, importType: .normal, moduleImport: moduleImport)
            modulesQueue.enqueue(parseQueueElement)
            return moduleImport

        case .sym_importGlobExpr:
            logger.debug("Not implemented")
        case .sym_functionLiteral:
            logger.debug("Not implemented")

        case .sym_qualifiedIdentifier: // QUALIFIED IDENTIFIER
            logger.debug("Starting building qualified identifier...")
            let identifier = document.getTextInByteRange(node.byteRange)
            logger.debug("Qualified identifier built successfully.")
            let range = ASTRange(pointRange: node.pointRange, byteRange: node.byteRange)
            return PklIdentifier(value: identifier, range: range, importDepth: importDepth, document: document, type: .qualifiedIdentifier)

        case .sym_typedIdentifier: // TYPED IDENTIFIER
            logger.debug("Starting building typed identifier...")
            var identifier: PklIdentifier?
            var typeAnnotation: PklTypeAnnotation?
            for childPosition in 0 ..< node.childCount {
                guard let childNode = node.child(at: childPosition) else {
                    continue
                }
                if childNode.symbol == PklTreeSitterSymbols.sym_identifier.rawValue {
                    identifier = await tsNodeToASTNode(node: childNode, in: document, importDepth: importDepth) as? PklIdentifier
                    continue
                }
                if childNode.symbol == PklTreeSitterSymbols.sym_typeAnnotation.rawValue {
                    typeAnnotation = await tsNodeToASTNode(node: childNode, in: document, importDepth: importDepth) as? PklTypeAnnotation
                    continue
                }
            }
            logger.debug("Typed identifier built successfully.")
            let range = ASTRange(pointRange: node.pointRange, byteRange: node.byteRange)
            return PklFunctionParameter(identifier: identifier, typeAnnotation: typeAnnotation, range: range, importDepth: importDepth, document: document)

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
