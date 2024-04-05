import Foundation
import Logging
import LanguageServer
import LanguageServerProtocol

public let loggerLabel: String = "pkl-lsp"

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

    public init(label: String, logLevel: Logger.Level, connnection: JSONRPCClientConnection, metadata: Logger.Metadata = [:]) {
        self.label = label
        self.logLevel = logLevel
        self.rpcConnection = connnection
        self.metadata = metadata
    }


    public func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, file: String, function: String, line: UInt) {
        Task {
            try await rpcConnection.sendNotification(.windowLogMessage(.init(type: loggerLevelToMessageType(.error), message: loggerLabel + ": " + message.description)))
        }
    }

    private func loggerLevelToMessageType(_ logLevel: Logger.Level) -> MessageType {
        switch logLevel {
        case .info:
            return .info
        case .debug:
            return .warning
        case .error:
            return .error
        case .trace:
            return .warning
        case .notice:
            return .warning
        case .warning:
            return .warning
        case .critical:
            return .error
        }
    }

}
