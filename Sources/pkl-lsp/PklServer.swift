import Foundation
import LanguageServer
import JSONRPC
import Semaphore
import Logging

public struct PklErrorHandler: ErrorHandler {
    let logger: Logger

    public func internalError(_ error: Error) async {
        logger.debug("LSP stream error: \(error)")
    }
}

public actor PklServer {

    let connection: JSONRPCClientConnection
    private let logger: Logger
    //private let dispatcher: EventDispatcher
    var exitSemaphore: AsyncSemaphore

    public init(_ dataChannel: DataChannel, logger: Logger) {
        self.logger = logger
        connection = JSONRPCClientConnection(dataChannel)
        let requestHandler = PklRequestHandler(connection: connection, logger: logger)

        exitSemaphore = AsyncSemaphore(value: 0)

        let documentProvider = DocumentProvider(connection: connection, logger: logger)
        let notificationHandler =
        PklNotificationHandler(connection: connection, logger: logger, documentProvider: documentProvider, exitSemaphore: exitSemaphore)
        let errorHandler = PklErrorHandler(logger: logger)

        //dispatcher = EventDispatcher(connection: connection, requestHandler: requestHandler, notificationHandler: notificationHandler, errorHandler: errorHandler)
    }

    public func run() async {
        logger.debug("Starting Pkl LSP Server...")
        //await dispatcher.run()
        logger.debug("Dispatcher completed.")
        await exitSemaphore.wait()
        logger.debug("Pkl LSP Server exited.")
    }
}

