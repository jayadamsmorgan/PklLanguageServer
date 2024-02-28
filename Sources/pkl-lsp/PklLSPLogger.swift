import Logging
import Foundation


public let loggerLabel: String = "pkl-lsp"

internal extension Logger {
    func trace(_ message: String) {
        let date = Date().description
        trace(Logger.Message(stringLiteral: "[\(date)]: [TRACE] \(message)"))
    }
    func debug(_ message: String) {
        let date = Date().description
        debug(Logger.Message(stringLiteral: "[\(date)]: [DEBUG] \(message)"))
    }

    func info(_ message: String) {
        let date = Date().description
        info(Logger.Message(stringLiteral: "[\(date)]: [INFO] \(message)"))
    }

    func warning(_ message: String) {
        let date = Date().description
        warning(Logger.Message(stringLiteral: "[\(date)]: [WARNING] \(message)"))
    }

    func error(_ message: String) {
        let date = Date().description
        error(Logger.Message(stringLiteral: "[\(date)]: [ERROR] \(message)"))
    }
}

public struct NullLogHandler: LogHandler, Sendable {

    public var logLevel: Logger.Level = .critical
    public var metadata: Logger.Metadata

    public subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get {
            return metadata[key]
        }
        set(newValue) {
            metadata[key] = newValue
        }
    }

    private let label: String

    public init(label: String, metadata: Logger.Metadata = [:]) {
        self.label = label
        self.metadata = metadata
    }

    public func log(level: Logger.Level,
        message: Logger.Message,
        metadata: Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt) {}

}

