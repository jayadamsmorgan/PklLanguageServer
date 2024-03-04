import Foundation
import JSONRPC
import LanguageServer
import Logging
import Semaphore

public struct PklErrorHandler: ErrorHandler {
    let logger: Logger

    public func internalError(_ error: Error) async {
        logger.debug("LSP stream error: \(error)")
    }
}

public actor PklServer {
    public static let pklLSVersion: String = "0.0.1-alpha"

    let connection: JSONRPCClientConnection
    private let logger: Logger
    private let dispatcher: EventDispatcher
    var exitSemaphore: AsyncSemaphore

    public init(_ dataChannel: DataChannel, logger: Logger) {
        self.logger = logger
        connection = JSONRPCClientConnection(dataChannel)
        let documentProvider = DocumentProvider(connection: connection, logger: logger)
        let requestHandler = PklRequestHandler(connection: connection, logger: logger, documentProvider: documentProvider)

        exitSemaphore = AsyncSemaphore(value: 0)

        let notificationHandler =
            PklNotificationHandler(connection: connection, logger: logger, documentProvider: documentProvider, exitSemaphore: exitSemaphore)
        let errorHandler = PklErrorHandler(logger: logger)

        dispatcher = EventDispatcher(connection: connection, requestHandler: requestHandler, notificationHandler: notificationHandler, errorHandler: errorHandler)
    }

    public func run() async {
        logger.debug("Starting Pkl LSP Server...")
        await dispatcher.run()
        logger.debug("Dispatcher completed.")
        await exitSemaphore.wait()
        logger.debug("Pkl LSP Server exited.")
    }
}
