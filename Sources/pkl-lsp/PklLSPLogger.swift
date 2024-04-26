import Foundation
import LanguageServer
import LanguageServerProtocol
import Logging

public let loggerLabel: String = "pkl-lsp-server"

extension Logger {
    func trace(_ message: String) {
        trace(Logger.Message(stringLiteral: message))
    }

    func debug(_ message: String) {
        debug(Logger.Message(stringLiteral: message))
    }

    func info(_ message: String) {
        info(Logger.Message(stringLiteral: message))
    }

    func warning(_ message: String) {
        warning(Logger.Message(stringLiteral: message))
    }

    func error(_ message: String) {
        error(Logger.Message(stringLiteral: message))
    }
}

public struct JSONRPCLogHandler: LogHandler, Sendable {
    public var logLevel: Logger.Level
    public var metadata: Logger.Metadata


    public subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get {
            metadata[key]
        }
        set(newValue) {
            metadata[key] = newValue
        }
    }

    private let label: String
    private let rpcConnection: JSONRPCClientConnection

    public init(label: String, logLevel: Logger.Level, connection: JSONRPCClientConnection, metadata: Logger.Metadata = [:]) {
        self.label = label
        self.logLevel = logLevel
        rpcConnection = connection
        self.metadata = metadata
    }

    public func log(level: Logger.Level, message: Logger.Message, metadata _: Logger.Metadata?, file _: String, function _: String, line _: UInt) {
        Task {
            try await rpcConnection.sendNotification(.windowLogMessage(.init(type: loggerLevelToMessageType(level), message: message.description)))
        }
    }

    private func loggerLevelToMessageType(_ logLevel: Logger.Level) -> MessageType {
        switch logLevel {
        case .info:
            .info
        case .debug:
            .log
        case .error:
            .warning
        case .trace:
            .log
        case .notice:
            .warning
        case .warning:
            .warning
        case .critical:
            .error
        }
    }
}
