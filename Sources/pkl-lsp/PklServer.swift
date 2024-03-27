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

public struct ServerFlags {
    public init(
        enableExperimentalFeatures: Bool,
        disabledFeatures: [FeatureType],
        maxImportDepth: Int
    ) {
        self.enableExperimentalFeatures = enableExperimentalFeatures
        self.disabledFeatures = disabledFeatures
        self.maxImportDepth = maxImportDepth
    }

    public let enableExperimentalFeatures: Bool
    public let disabledFeatures: [FeatureType]

    public let maxImportDepth: Int
}

public actor PklServer {
    public static let pklLSVersion: String = "0.0.1-alpha"

    let connection: JSONRPCClientConnection
    private let logger: Logger
    private let dispatcher: EventDispatcher
    var exitSemaphore: AsyncSemaphore

    public init(_ dataChannel: DataChannel, logger: Logger, serverFlags: ServerFlags) {
        self.logger = logger
        connection = JSONRPCClientConnection(dataChannel)
        let treeSitterParser = TreeSitterParser(logger: logger, maxImportDepth: serverFlags.maxImportDepth)
        let documentProvider = DocumentProvider(connection: connection, logger: logger, treeSitterParser: treeSitterParser, serverFlags: serverFlags)
        treeSitterParser.setDocumentProvider(documentProvider)
        let requestHandler = PklRequestHandler(connection: connection, logger: logger, documentProvider: documentProvider)

        exitSemaphore = AsyncSemaphore(value: 0)

        let notificationHandler =
            PklNotificationHandler(connection: connection, logger: logger, documentProvider: documentProvider, exitSemaphore: exitSemaphore)
        let errorHandler = PklErrorHandler(logger: logger)

        dispatcher = EventDispatcher(connection: connection, requestHandler: requestHandler, notificationHandler: notificationHandler, errorHandler: errorHandler)
    }

    public func run() async {
        logger.info("Starting Pkl LSP Server...")
        await dispatcher.run()
        logger.debug("Dispatcher completed.")
        await exitSemaphore.wait()
        logger.info("Pkl LSP Server exited.")
    }
}
