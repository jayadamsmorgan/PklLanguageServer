import Foundation
import LanguageServerProtocol
import SwiftTreeSitter

public extension Point {
    func toPosition() -> Position {
        Position((Int(row), Int(column)))
    }
}
