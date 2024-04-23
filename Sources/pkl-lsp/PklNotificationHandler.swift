import Foundation
import JSONRPC
import LanguageServer
import LanguageServerProtocol
import Logging
import Semaphore

public struct PklNotificationHandler: NotificationHandler {
    public let connection: JSONRPCClientConnection
    public let logger: Logger
    var documentProvider: DocumentProvider
    var exitSemaphore: AsyncSemaphore

    public func internalError(_ error: Error) async {
        logger.debug("LSP stream error: \(error)")
    }

    public func handleNotification(_ notification: ClientNotification) async {
        let t0 = Date()
        logger.trace("Begin handle notification: \(notification.method)")
        await defaultNotificationDispatch(notification)
        let t = Date().timeIntervalSince(t0)
        logger.trace("Complete handle notification: \(notification.method), after \(Int(t * 1000))ms")
    }

    public func initialized(_: InitializedParams) async {}

    public func exit() async {
        await connection.stop()
        exitSemaphore.signal()
    }

    public func textDocumentDidOpen(_ params: DidOpenTextDocumentParams) async {
        await documentProvider.registerDocument(params)
    }

    public func textDocumentDidChange(_ params: DidChangeTextDocumentParams) async {
        await documentProvider.updateDocument(params)
    }

    public func textDocumentDidClose(_ params: DidCloseTextDocumentParams) async {
        await documentProvider.unregisterDocument(params)
    }

    public func textDocumentWillSave(_: WillSaveTextDocumentParams) async {}

    public func textDocumentDidSave(_: DidSaveTextDocumentParams) async {}

    public func protocolCancelRequest(_ params: CancelParams) async {
        // NOTE: For cancel to work we must pass JSONRPC request ids to handlers
        logger.trace("Cancel request: \(params.id)")
    }

    public func protocolSetTrace(_: SetTraceParams) async {}

    public func workspaceDidChangeWatchedFiles(_: DidChangeWatchedFilesParams) async {}

    public func windowWorkDoneProgressCancel(_: WorkDoneProgressCancelParams) async {}

    public func workspaceDidChangeWorkspaceFolders(_ params: DidChangeWorkspaceFoldersParams) async {
        await documentProvider.workspaceDidChangeWorkspaceFolders(params)
    }

    public func workspaceDidChangeConfiguration(_: DidChangeConfigurationParams) async {}

    public func workspaceDidCreateFiles(_: CreateFilesParams) async {}

    public func workspaceDidRenameFiles(_: RenameFilesParams) async {}

    public func workspaceDidDeleteFiles(_: DeleteFilesParams) async {}
}
