import Foundation
import JSONRPC
import UniSocket

public extension DataChannel {
    init(socket: UniSocket) {
        let writeHandler = { @Sendable data in
            try socket.send(data)
        }

        let dataSequence = DataSequence {
            do {
                let d = try socket.recv()
                return d
            } catch {
                print("DataChannel socket error: \(error)")
                return nil
            }

        } onCancel: { @Sendable () in print("Canceled.") }

        self.init(writeHandler: writeHandler, dataSequence: dataSequence)
    }
}
