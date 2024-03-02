import JSONRPC
import LanguageServerProtocol
import LanguageServer
import Foundation
import Semaphore
import Logging


public struct PklRequestHandler : RequestHandler, Sendable {
    public let connection: JSONRPCClientConnection
    public let logger: Logger

    var documentProvider: DocumentProvider

    public init(connection: JSONRPCClientConnection, logger: Logger, documentProvider: DocumentProvider) {
        self.connection = connection
        self.logger = logger
        self.documentProvider = documentProvider
    }

    public func internalError(_ error: Error) async {
        logger.error("LSP stream error: \(error)")
    }

    public func handleRequest(id: JSONId, request: ClientRequest) async {
        let t0 = Date()
        logger.trace("Begin handle request: \(request)")
        await defaultRequestDispatch(id: id, request: request)
        let t = Date().timeIntervalSince(t0)
        logger.trace("Complete handle request: \(request.method), after \(Int(t*1000))ms")
    }

    public func initialize(id: JSONId, params: InitializeParams) async -> Result<InitializationResponse, AnyJSONRPCResponseError> {
        logger.trace("Initialize request id \(id)")
        return await documentProvider.initialize(params)
    }

    public func completionItemResolve(id: JSONId, params: CompletionItem) async -> Response<CompletionItem> {
        logger.trace("Completion Item Resolve request id \(id)")
        return .success(params)
    }

    let CompletionJSONRPCError = AnyJSONRPCResponseError(code: 15, message: "Could not complete document.")

    public func completion(id: JSONId, params: CompletionParams) async -> Response<CompletionResponse> {
        logger.trace("Completion request id \(id)")
        return .success(await documentProvider.provideCompletion(params: params))
    
    }

    public func semanticTokensFull(id: JSONId, params: SemanticTokensParams) async -> Response<SemanticTokensResponse> {
        logger.trace("Semantic Tokens request id \(id)")
        return .success(await documentProvider.provideSemanticTokens(params: params))
    }

    public func shutdown(id: JSONId) async {
        logger.trace("Shutdown request id \(id)")
    }

    public func definition(id: JSONId, params: TextDocumentPositionParams) async -> Response<DefinitionResponse> {
        logger.trace("Definition request id \(id)")
        return .success(await documentProvider.provideDefinition(params: params))
    }

    public func documentSymbol(id: JSONId, params: DocumentSymbolParams) async -> Result<DocumentSymbolResponse, AnyJSONRPCResponseError> {
        logger.trace("Document Symbol request id \(id)")
        return .success(await documentProvider.provideDocumentSymbols(params: params))
    }

    public func rename(id: JSONId, params: RenameParams) async -> Response<RenameResponse> {
        logger.trace("Rename request id \(id)")
        return .success(await documentProvider.provideRenaming(params: params))
    }
}

