import Logging

public let loggerLabel: String = "pkl-lsp"

internal extension Logger {
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
