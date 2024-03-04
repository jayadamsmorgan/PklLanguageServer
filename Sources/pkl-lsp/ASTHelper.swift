import Foundation
import LanguageServerProtocol
import Logging

public enum ASTHelper {
    private static func iterate<T: ASTNode>(node: any ASTNode, array: inout [T]) {
        if let children = node.children {
            for child in children {
                if let child = child as? T {
                    array.append(child)
                }
                iterate(node: child, array: &array)
            }
        }
    }

    static func getPositionContext(module: any ASTNode, position: Position) -> (any ASTNode)? {
        for node in module.children ?? [] {
            if node.positionStart.line <= position.line,
               node.positionEnd.line >= position.line,
               node.positionStart.character / 2 <= position.character,
               node.positionEnd.character / 2 >= position.character
            {
                if let context = getPositionContext(module: node, position: position) {
                    return context
                }
                return node
            }
        }
        return nil
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
