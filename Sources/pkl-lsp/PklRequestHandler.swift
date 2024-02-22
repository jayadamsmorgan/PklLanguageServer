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
        return await documentProvider.initialize(params)
    }

    public func completionItemResolve(id: JSONId, params: CompletionItem) async -> Response<CompletionItem> {
        logger.debug("CompletionItemResolve request: \(params)")
        return .success(params)
    }

    let CompletionJSONRPCError = AnyJSONRPCResponseError(code: 15, message: "Could not complete document.")

    public func completion(id: JSONId, params: CompletionParams) async -> Response<CompletionResponse> {
        guard let completionList = await documentProvider.complete(completionParams: params) else {
            return .failure(CompletionJSONRPCError)
        }
        return .success(CompletionResponse(.optionB(completionList)))
    
    }

    public func semanticTokensFull(id: JSONId, params: SemanticTokensParams) async -> Response<SemanticTokensResponse> {
        return .success(SemanticTokens(tokens: [.init(line: 0, char: 1, length: 1, type: 0)]))
    }

    public func shutdown(id: JSONId) async {
    }

    public func definition(id: JSONId, params: TextDocumentPositionParams) async -> Response<DefinitionResponse> {
        logger.debug("definition request: \(params)")
        return .success(.optionA(.init(uri: .init("file:///home/ubuntu/Documents/PklLanguageServer/test.pkl"), range: .init(start: .init((0, 0)), end: .init((0, 0))))))
    }

    public func documentSymbol(id: JSONId, params: DocumentSymbolParams) async -> Result<DocumentSymbolResponse, AnyJSONRPCResponseError> {
        let documentSymbolResponse = DocumentSymbolResponse(.optionA([DocumentSymbol(name: "Hello, World!", kind: .function, range: .init(start: .init(line: 0, character: 0), end: .init(line: 0, character: 0)), selectionRange: .init(start: .init(line: 0, character: 0), end: .init(line: 0, character: 0)), children: nil)]))
        return .success(documentSymbolResponse)
    }

    // public func diagnostics(id: JSONId, params: DocumentDiagnosticParams) async -> Response<DocumentDiagnosticReport> {
    //     logger.debug("Diagnostics triggered: \(params)")
    //     return .failure(CompletionJSONRPCError)
    // }

}
