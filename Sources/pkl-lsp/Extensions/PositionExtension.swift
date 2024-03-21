import Foundation
import LanguageServerProtocol
import SwiftTreeSitter

public extension Position {
    func getPoint() -> Point {
        Point(row: line, column: character)
    }
}
