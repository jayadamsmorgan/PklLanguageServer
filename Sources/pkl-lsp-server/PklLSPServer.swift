import ArgumentParser
import Foundation
import JSONRPC
import pkl_lsp
import Puppy
import UniSocket

// Allow loglevel as `ArgumentParser.Option`
extension Logger.Level: ExpressibleByArgument {}

extension Bool {
    var intValue: Int {
        self ? 1 : 0
    }
}

@main
struct PklLSPServer: AsyncParsableCommand {
    static var configuration = CommandConfiguration(commandName: "pkl-lsp-server")

    @Option(name: .shortAndLong, help: "Log level")
    var log: Logger.Level = .info

    @Option(name: [.customShort("f"), .long], help: "Log file")
    var logFile: String?

    @Option(name: .shortAndLong, help: "Named pipe transport")
    var pipe: String?

    @Option(name: .shortAndLong, help: "Socket transport")
    var socket: String?

    @Flag(name: .shortAndLong, help: "Print language server version")
    var version: Bool = false

    @Flag(name: .long, help: "Disable document diagnostics")
    var disableDiagnostics: Bool = false

    @Flag(name: .long, help: "Disable diagnostics in included modules")
    var disableIncludeDiagnostics: Bool = false

    @Option(name: .long, help: "Maximum number of dependencies parsed")
    var importDepth: Int = 3

    var stdio: Bool {
        !(pipe != nil || socket != nil)
    }

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
        guard let _ = logFile else {
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
            StreamLogHandler.standardOutput(label: label),
        ])
    }

    func validate() throws {
        let numTransports = stdio.intValue + (pipe != nil).intValue + (socket != nil).intValue
        guard numTransports == 1 else {
            throw ValidationError("Exactly one transport method must be defined (stdio (default), pipe (--pipe), socket (--socket))")
        }
        if importDepth < 0 {
            throw ValidationError("Import depth must be at least 0")
        }
    }

    func run(logger: Logger, channel: DataChannel) async {
        let serverFlags: ServerFlags = .init(
            disableDiagnostics: disableDiagnostics,
            disableIncludeDiagnostics: disableIncludeDiagnostics,
            maxImportDepth: importDepth
        )
        let server = PklServer(channel, logger: logger, serverFlags: serverFlags)
        await server.run()
    }

    func run() async throws {
        if version {
            print("Pkl Language Server version \(PklServer.pklLSVersion)")
            return
        }
        var logger: Logger?
        if let logFile {
            let logFileURL = URL(fileURLWithPath: logFile)
            let fileLogger = try FileLogger(loggerLabel, logLevel: puppyLevel(log), fileURL: logFileURL)
            logger = Logger(label: fileLogger.label) { logHandlerFactory($0, fileLogger: fileLogger) }
            logger?.logLevel = log
        } else {
            logger = Logger(label: loggerLabel)
            logger?.logLevel = log
        }

        if stdio {
            await run(logger: logger!, channel: DataChannel.stdioPipe())
        }

        if let socket {
            let socket = try UniSocket(type: .tcp, peer: socket, timeout: (connect: 5, read: nil, write: 5))
            try socket.attach()
            await run(logger: logger!, channel: DataChannel(socket: socket))
        } else if let pipe {
            let socket = try UniSocket(type: .local, peer: pipe, timeout: (connect: 5, read: nil, write: 5))
            try socket.attach()
            await run(logger: logger!, channel: DataChannel(socket: socket))
        }
    }
}
