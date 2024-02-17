import JSONRPC
import LanguageServer
import LanguageServerProtocol

@main
enum EntryPoint {
    static func main() async throws {
        let channel = DataChannel.stdioPipe()
        let connection = JSONRPCClientConnection(channel)
        while (true) {
            

        }
    }
}
