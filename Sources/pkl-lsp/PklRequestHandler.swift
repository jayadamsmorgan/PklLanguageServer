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
    // var ast: AST { documentProvider.ast }
    // var program: TypedProgram? { documentProvider.program }
    // var initTask: Task<TypedProgram, Error>

    public init(connection: JSONRPCClientConnection, logger: Logger, documentProvider: DocumentProvider) {
        self.connection = connection
        self.logger = logger
        self.documentProvider = documentProvider
    }

    public func internalError(_ error: Error) async {
        logger.debug("LSP stream error: \(error)")
    }

    public func handleRequest(id: JSONId, request: ClientRequest) async {
        let t0 = Date()
        logger.debug("Begin handle request: \(request.method)")
        await defaultRequestDispatch(id: id, request: request)
        let t = Date().timeIntervalSince(t0)
        logger.debug("Complete handle request: \(request.method), after \(Int(t*1000))ms")
    }

    public func prepareTypeHeirarchy(id: JSONId, params: TypeHierarchyPrepareParams) async -> Response<PrepareTypeHeirarchyResponse> {
        // Do nothing
    }


    public func initialize(id: JSONId, params: InitializeParams) async -> Result<InitializationResponse, AnyJSONRPCResponseError> {
        return await documentProvider.initialize(params)
    }

    public func shutdown(id: JSONId) async {
    }

    public func definition(id: JSONId, params: TextDocumentPositionParams) async -> Result<DefinitionResponse, AnyJSONRPCResponseError> {
    }

    public func documentSymbol(id: JSONId, params: DocumentSymbolParams) async -> Result<DocumentSymbolResponse, AnyJSONRPCResponseError> {

    }

    public func diagnostics(id: JSONId, params: DocumentDiagnosticParams) async -> Result<DocumentDiagnosticReport, AnyJSONRPCResponseError> {
    }


}
