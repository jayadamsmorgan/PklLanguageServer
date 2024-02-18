import JSONRPC
import LanguageServerProtocol
import LanguageServer
import Foundation
import Semaphore
import Logging

public struct PklNotificationHandler : NotificationHandler {
    public let connection: JSONRPCClientConnection
    public let logger: Logger
    var documentProvider: DocumentProvider
    var exitSemaphore: AsyncSemaphore

    public func internalError(_ error: Error) async {
        logger.debug("LSP stream error: \(error)")
    }

    public func handleNotification(_ notification: ClientNotification) async {
        let t0 = Date()
        logger.debug("Begin handle notification: \(notification.method)")
        await defaultNotificationDispatch(notification)
        let t = Date().timeIntervalSince(t0)
        logger.debug("Complete handle notification: \(notification.method), after \(Int(t*1000))ms")
    }

    private func withErrorLogging(_ fn: () async throws -> Void) async {
        do {
            try await fn()
        }
        catch {
            logger.debug("Error: \(error)")
        }
    }

    public func initialized(_ params: InitializedParams) async {

    }

    public func exit() async {
        await connection.stop()
        exitSemaphore.signal()
    }

    // public func textDocumentDidOpen(_ params: DidOpenTextDocumentParams) async {
    //     await documentProvider.registerDocument(params)
    // }
    //
    // public func textDocumentDidChange(_ params: DidChangeTextDocumentParams) async {
    //     await documentProvider.updateDocument(params)
    // }
    //
    // public func textDocumentDidClose(_ params: DidCloseTextDocumentParams) async {
    //     await documentProvider.unregisterDocument(params)
    // }
    //
    public func textDocumentWillSave(_ params: WillSaveTextDocumentParams) async {

    }

    public func textDocumentDidSave(_ params: DidSaveTextDocumentParams) async {
    }

    public func protocolCancelRequest(_ params: CancelParams) async {
        // NOTE: For cancel to work we must pass JSONRPC request ids to handlers
        logger.debug("Cancel request: \(params.id)")
    }

    public func protocolSetTrace(_ params: SetTraceParams) async {

    }

    public func workspaceDidChangeWatchedFiles(_ params: DidChangeWatchedFilesParams) async {

    }

    public func windowWorkDoneProgressCancel(_ params: WorkDoneProgressCancelParams) async {

    }

    public func workspaceDidChangeWorkspaceFolders(_ params: DidChangeWorkspaceFoldersParams) async {
        await documentProvider.workspaceDidChangeWorkspaceFolders(params)
    }

    public func workspaceDidChangeConfiguration(_ params: DidChangeConfigurationParams)  async {

    }

    public func workspaceDidCreateFiles(_ params: CreateFilesParams) async {

    }

    public func workspaceDidRenameFiles(_ params: RenameFilesParams) async {

    }

    public func workspaceDidDeleteFiles(_ params: DeleteFilesParams) async {

    }

}
