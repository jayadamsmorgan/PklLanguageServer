import Foundation
import LanguageServerProtocol
import Logging

public class DiagnosticsHandler {
    public let logger: Logger

    public init(logger: Logger) {
        self.logger = logger
    }
}
