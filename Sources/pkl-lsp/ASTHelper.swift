import Foundation
import LanguageServerProtocol
import Logging

public enum ASTHelper {
    public static func iterate<T: ASTNode>(node: any ASTNode, array: inout [T]) {
        if let children = node.children {
            for child in children {
                if let child = child as? T {
                    array.append(child)
                }
                iterate(node: child, array: &array)
            }
        }
    }

    static func enumerate(node: any ASTNode, block: (any ASTNode) -> Void) {
        if let children = node.children {
            for child in children {
                block(node)
                enumerate(node: child, block: block)
            }
        }
    }

    static func enumerate(node: any ASTNode, block: (any ASTNode) async -> Void) async {
        if let children = node.children {
            for child in children {
                await block(node)
                await enumerate(node: child, block: block)
            }
        }
    }

    static func getPositionContext(module: any ASTNode, position: Position) -> (any ASTNode)? {
        for node in module.children ?? [] {
            if node.range.positionRange.lowerBound.line <= position.line,
               node.range.positionRange.upperBound.line >= position.line,
               node.range.positionRange.lowerBound.character / 2 <= position.character,
               node.range.positionRange.upperBound.character / 2 >= position.character
            {
                if let context = getPositionContext(module: node, position: position) {
                    return context
                }
                return node
            }
        }
        return nil
    }

}
