import Foundation
import LanguageServerProtocol
import Logging


public struct ASTHelper {

    private static func iterate<T : ASTNode>(node: any ASTNode, array: inout [T]) {
        if let children = node.children {
            for child in children {
                if let child = child as? T {
                    array.append(child)
                }
                iterate(node: child, array: &array)
            }
        }
    }

    static func getASTIdentifiers(node: any ASTNode) -> [PklIdentifier] {
        var identifiers: [PklIdentifier] = []
        iterate(node: node, array: &identifiers)
        return identifiers
    }

    static func getASTClasses(node: any ASTNode) -> [PklClass] {
        var classes: [PklClass] = []
        iterate(node: node, array: &classes)
        return classes
    }

}

