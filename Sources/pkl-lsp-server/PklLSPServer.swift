import ArgumentParser
import Foundation
import JSONRPC
import LanguageServer
import Logging
import pkl_lsp
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
    var log: Logger.Level = .error

    @Option(name: .shortAndLong, help: "Named pipe transport")
    var pipe: String?

    @Option(name: .shortAndLong, help: "Socket transport")
    var socket: String?

    @Flag(name: .shortAndLong, help: "Print language server version")
    var version: Bool = false

    @Flag(name: .shortAndLong, help: "Enable experimental features which are still in development (semanticTokens, rename, diagnostics)")
    var enableExperimentalFeatures: Bool = false

    @Option(name: .shortAndLong, help: "Maximum number of dependencies parsed in depth")
    var importDepth: Int = 3

    @Option(name: .shortAndLong, help: "Disable feature")
    var disableFeature: [FeatureType] = []

    var stdio: Bool {
        pipe == nil && socket == nil
    }

    func logHandlerFactory(_ label: String, rpcConnection: JSONRPCClientConnection) -> LogHandler {
        let rpcLogHandler = JSONRPCLogHandler(label: label, logLevel: log, connnection: rpcConnection)

        return MultiplexLogHandler([
            StreamLogHandler.standardOutput(label: label),
            rpcLogHandler,
        ])
    }

    func validate() throws {
        if pipe != nil, socket != nil {
            throw ValidationError("Exactly one transport method must be defined (stdio (default), pipe (--pipe), socket (--socket))")
        }
        if importDepth < 0 {
            throw ValidationError("Import depth must be at least 0")
        }
    }

    func run(channel: DataChannel) async throws {
        let connection = JSONRPCClientConnection(channel)

        var logger = Logger(label: loggerLabel) { logHandlerFactory($0, rpcConnection: connection) }
        logger.logLevel = log

        let serverFlags: ServerFlags = .init(
            enableExperimentalFeatures: enableExperimentalFeatures,
            disabledFeatures: disableFeature,
            maxImportDepth: importDepth
        )

        let server = PklServer(connection: connection, logger: logger, serverFlags: serverFlags)
        await server.run()
    }

    func run() async throws {
        if version {
            print("Pkl Language Server version \(PklServer.pklLSVersion)")
            return
        }

        if stdio {
            try await run(channel: DataChannel.stdioPipe())
        }

        if let socket {
            let socket = try UniSocket(type: .tcp, peer: socket, timeout: (connect: 5, read: nil, write: 5))
            try socket.attach()
            try await run(channel: DataChannel(socket: socket))
        } else if let pipe {
            let socket = try UniSocket(type: .local, peer: pipe, timeout: (connect: 5, read: nil, write: 5))
            try socket.attach()
            try await run(channel: DataChannel(socket: socket))
        }
    }
}
