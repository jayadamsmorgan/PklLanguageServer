import Foundation

public enum TokenType: UInt32, CaseIterable {
    case `class`
    case object
    case function
    case number
    case string
    case variable
    case `operator`
    case keyword
    case unknown

    var description: String {
        String(describing: self)
    }
}
