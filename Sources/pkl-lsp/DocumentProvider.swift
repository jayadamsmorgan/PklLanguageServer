import JSONRPC
import Foundation
import LanguageServerProtocol
import LanguageServer
import Logging

public protocol TextDocumentProtocol {
    var uri: DocumentUri { get }
}

extension TextDocumentIdentifier : TextDocumentProtocol {}
extension TextDocumentItem : TextDocumentProtocol {}
extension VersionedTextDocumentIdentifier : TextDocumentProtocol {}

public enum GetDocumentContextError : Error {
    case invalidUri(DocumentUri)
    case documentNotOpened(DocumentUri)
}

public actor DocumentProvider {
    private var documents: [DocumentUri:Document]
    public let logger: Logger
    let connection: JSONRPCClientConnection
    var rootUri: String?
    var workspaceFolders: [WorkspaceFolder]

    public init(connection: JSONRPCClientConnection, logger: Logger) {
        self.logger = logger
        documents = [:]
        self.connection = connection
        self.workspaceFolders = []
    }


    private func getServerCapabilities() -> ServerCapabilities {
        var s = ServerCapabilities()
        let documentSelector = DocumentFilter(pattern: "**/*.pkl")
        let tokenLegend = SemanticTokensLegend(tokenTypes: TokenType.allCases.map { $0.description }, tokenModifiers: ["private", "public"])
        s.completionProvider = .init(
            workDoneProgress: false,
            triggerCharacters: ["."],
            allCommitCharacters: [],
            resolveProvider: false,
            completionItem: CompletionOptions.CompletionItem(labelDetailsSupport: true))
        s.textDocumentSync = .optionA(TextDocumentSyncOptions(openClose: false, change: TextDocumentSyncKind.full, willSave: false, willSaveWaitUntil: false, save: nil))
        s.textDocumentSync = .optionB(TextDocumentSyncKind.full)
        s.definitionProvider = .optionA(true)
        s.documentSymbolProvider = .optionA(true)
        s.semanticTokensProvider = .optionB(SemanticTokensRegistrationOptions(documentSelector: [documentSelector], legend: tokenLegend, range: .optionA(false), full: .optionA(true)))
        s.diagnosticProvider = .optionA(DiagnosticOptions(interFileDependencies: false, workspaceDiagnostics: false))
        return s
    }


    public func initialize(_ params: InitializeParams) async -> Result<InitializationResponse, AnyJSONRPCResponseError> {

        if let workspaceFolders = params.workspaceFolders {
            self.workspaceFolders = workspaceFolders
        }

        if let rootUri = params.rootUri {
            self.rootUri = rootUri
        }
            else if let rootPath = params.rootPath {
            self.rootUri = rootPath
        }

        logger.info("Initialize in working directory: \(FileManager.default.currentDirectoryPath), with rootUri: \(rootUri ?? "nil"), workspace folders: \(workspaceFolders)")

        let serverInfo = ServerInfo(name: "pkl", version: "0.0.1")
        return .success(InitializationResponse(capabilities: getServerCapabilities(), serverInfo: serverInfo))
    }

    public func workspaceDidChangeWorkspaceFolders(_ params: DidChangeWorkspaceFoldersParams) async {
        let removed = params.event.removed
        let added = params.event.added
        workspaceFolders = workspaceFolders.filter { removed.contains($0) }
        workspaceFolders.append(contentsOf: added)
    }

    func getRelativePathInWorkspace(_ uri: DocumentUri, relativeTo workspace: DocumentUri) -> String? {
        if uri.starts(with: workspace) {
            let start = uri.index(uri.startIndex, offsetBy: workspace.count)
            let tail = uri[start...]
            let relPath = tail.trimmingPrefix("/")
            return String(relPath)
        }
            else {
            return nil
        }
    }

    struct WorkspaceFile {
        let workspace: DocumentUri
        let relativePath: String
    }


    func getWorkspaceFile(_ uri: DocumentUri) -> WorkspaceFile? {
        var wsRoots = workspaceFolders.map { $0.uri }
        if let rootUri = rootUri {
            wsRoots.append(rootUri)
        }

        var closest: WorkspaceFile?

        // Look for the closest matching workspace root
        for root in wsRoots {
            if let relPath = getRelativePathInWorkspace(uri, relativeTo: root) {
                if closest == nil || relPath.count < closest!.relativePath.count {
                    closest = WorkspaceFile(workspace: root, relativePath: relPath)
                }
            }
        }

        return closest
    }

    func uriAsFilepath(_ uri: DocumentUri) -> String? {
        guard let url = URL.init(string: uri) else {
            return nil
        }

        return url.path
    }

    // https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#uri
    // > Over the wire, it will still be transferred as a string, but this guarantees that the contents of that string can be parsed as a valid URI.
    public static func validateDocumentUri(_ uri: DocumentUri) -> DocumentUri? {
        if let url = URL(string: uri) {

            // Make sure the URL is a fully qualified path with scheme
            if url.scheme != nil {
                return uri
            }
        }

        return nil
    }

    public static func validateDocumentUrl(_ uri: DocumentUri) -> URL? {
        if let url = URL(string: uri) {

            // Make sure the URL is a fully qualified path with scheme
            if url.scheme != nil {
                return url
            }
        }

        return nil
    }

    public func updateDocument(_ params: DidChangeTextDocumentParams) async {
        let uri = params.textDocument.uri
        guard let documentUri = DocumentProvider.validateDocumentUri(uri) else {
            logger.error("Invalid document uri: \(uri)")
            return
        }

        guard let document = documents[documentUri] else {
            logger.error("Document not opened: \(uri)")
            return
        }

        let nextVersion = params.textDocument.version
        let changes = params.contentChanges
        do {
            let newDocument = try document.withAppliedChanges(changes, nextVersion: nextVersion)
            documents[documentUri] = newDocument
        }
        catch {
            logger.error("Error updating document: \(error)")
        }
    }

    public func registerDocument(_ params: DidOpenTextDocumentParams) async {
        let uri = params.textDocument.uri
        guard let documentUri = DocumentProvider.validateDocumentUri(uri) else {
            logger.error("Invalid document uri: \(uri)")
            return
        }

        let document = Document(textDocument: params.textDocument)
        documents[documentUri] = document
    }

    public func unregisterDocument(_ params: DidCloseTextDocumentParams) async {
        let uri = params.textDocument.uri
        guard let documentUri = DocumentProvider.validateDocumentUri(uri) else {
            logger.error("Invalid document uri: \(uri)")
            return
        }

        documents[documentUri] = nil
    }

}

