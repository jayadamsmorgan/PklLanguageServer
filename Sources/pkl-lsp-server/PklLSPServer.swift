import Foundation
import ArgumentParser
import JSONRPC
import Puppy
import UniSocket
import pkl_lsp


// Allow loglevel as `ArgumentParser.Option`
extension Logger.Level : ExpressibleByArgument { }

extension Bool {
    var intValue: Int {
        self ? 1 : 0
    }
}

@main
struct PklLSPServer : AsyncParsableCommand {

    static var configuration = CommandConfiguration(commandName: "pkl-lsp-server")

    @Option(help: "Log level")
    var log: Logger.Level = .debug

    @Option(help: "Log file")
    var logFile: String = "pkl-lsp-server.log"
    
    @Flag(help: "Stdio transport")
    var stdio: Bool = false

    @Option(help: "Named pipe transport")
    var pipe: String?

    @Option(help: "Socket transport")
    var socket: String?

    func puppyLevel(_ level: Logger.Level) -> LogLevel {
      switch level {
        case .trace: .trace
        case .debug: .debug
        case .info: .info
        case .notice: .notice
        case .warning: .warning
        case .error: .error
        case .critical: .critical
      }
    }

    func logHandlerFactory(_ label: String, fileLogger: FileLogger) -> LogHandler {
        if let _ = ProcessInfo.processInfo.environment["PKL_LSP_DISABLE_LOGGING"] {
            return NullLogHandler(label: label)
        }

        var puppy = Puppy()
        puppy.add(fileLogger)

        let puppyHandler = PuppyLogHandler(label: label, puppy: puppy)

        if stdio {
            return puppyHandler
        }

        return MultiplexLogHandler([
            puppyHandler,
            StreamLogHandler.standardOutput(label: label)
        ])
    }

    func validate() throws {
        let numTransports = stdio.intValue + (pipe != nil).intValue + (socket != nil).intValue
        guard numTransports == 1 else {
            throw ValidationError("Exactly one transport method must be defined (stdio, pipe, socket)")
        }
    }

    func run(logger: Logger, channel: DataChannel) async {
        let server = PklServer(channel, logger: logger)
        await server.run()
    }

    func run() async throws {
        let logFileURL = URL(fileURLWithPath: logFile)
        let fileLogger = try FileLogger(loggerLabel, logLevel: puppyLevel(log), fileURL: logFileURL)
        var logger = Logger(label: fileLogger.label) { logHandlerFactory($0, fileLogger: fileLogger)}
        logger.logLevel = log

        if stdio {
            await run(logger: logger, channel: DataChannel.stdioPipe())
        }

        if let socket = socket {
            let socket = try UniSocket(type: .tcp, peer: socket, timeout: (connect: 5, read: nil, write: 5))
            try socket.attach()
            await run(logger: logger, channel: DataChannel(socket: socket))
        }
        else if let pipe = pipe {
            let socket = try UniSocket(type: .local, peer: pipe, timeout: (connect: 5, read: nil, write: 5))
            try socket.attach()
            await run(logger: logger, channel: DataChannel(socket: socket))
        }
    }
}

