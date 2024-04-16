import Foundation
import LanguageServerProtocol
import Logging

public enum ASTHelper {
    public static func iterate<T: ASTNode>(node: ASTNode, array: inout [T]) {
        if let children = node.children {
            for child in children {
                if let child = child as? T {
                    array.append(child)
                }
                iterate(node: child, array: &array)
            }
        }
    }

    public static func allEndNodes(node: ASTNode, importDepth: Int? = nil) -> [ASTNode] {
        var nodes = [ASTNode]()
        guard let children = node.children else {
            return [node]
        }
        for child in children {
            guard let importDepth else {
                nodes.append(contentsOf: allEndNodes(node: child))
                continue
            }
            if child.importDepth == importDepth {
                nodes.append(contentsOf: allEndNodes(node: child))
            }
        }
        return nodes
    }

    public static func allEndNodes<T: ASTNode>(node: ASTNode, importDepth: Int? = nil) -> [T] {
        var nodes = [T]()
        guard let children = node.children else {
            if let node = node as? T {
                return [node]
            }
            return []
        }
        for child in children {
            guard let importDepth else {
                nodes.append(contentsOf: allEndNodes(node: child))
                continue
            }
            if child.importDepth == importDepth {
                nodes.append(contentsOf: allEndNodes(node: child))
            }
        }
        return nodes
    }

    public static func allNodes(node: ASTNode, importDepth: Int? = nil) -> [ASTNode] {
        var nodes = [ASTNode]()
        nodes.append(node)
        if let children = node.children {
            for child in children {
                if let importDepth {
                    if child.importDepth == importDepth {
                        nodes.append(contentsOf: allNodes(node: child))
                    }
                } else {
                    nodes.append(contentsOf: allNodes(node: child))
                }
            }
        }
        return nodes
    }

    public static func allNodes<T: ASTNode>(node: ASTNode, importDepth: Int? = nil) -> [T] {
        var nodes = [T]()
        if let node = node as? T {
            nodes.append(node)
        }
        if let children = node.children {
            for child in children {
                if let importDepth {
                    if child.importDepth == importDepth {
                        nodes.append(contentsOf: allNodes(node: child))
                    }
                } else {
                    nodes.append(contentsOf: allNodes(node: child))
                }
            }
        }
        return nodes
    }

    static func enumerate(node: inout ASTNode, block: (inout ASTNode) -> Void) {
        block(&node)
        if let children = node.children {
            for var child in children {
                enumerate(node: &child, block: block)
            }
        }
    }

    static func enumerate(node: inout ASTNode, block: (inout ASTNode) async -> Void) async {
        await block(&node)
        if let children = node.children {
            for var child in children {
                await enumerate(node: &child, block: block)
            }
        }
    }

    static func enumerate(node: ASTNode, block: (ASTNode) -> Void) {
        block(node)
        if let children = node.children {
            for child in children {
                enumerate(node: child, block: block)
            }
        }
    }

    static func enumerate(node: ASTNode, block: (ASTNode) async -> Void) async {
        await block(node)
        if let children = node.children {
            for child in children {
                await enumerate(node: child, block: block)
            }
        }
    }

    static func getPositionContext(module: ASTNode, position: Position, importDepth: Int? = nil) -> ASTNode? {
        var contextNode: ASTNode?
        var smallestRange = Int.max

        enumerate(node: module) { node in
            if let importDepth, node.importDepth > importDepth {
                return
            }
            let range = node.range.positionRange
            if position.line >= range.lowerBound.line,
               position.line > range.lowerBound.line || position.character >= range.lowerBound.character / 2,
               position.line <= range.upperBound.line,
               position.line < range.upperBound.line || position.character <= range.upperBound.character / 2
            {
                let rangeSize = (range.upperBound.line - range.lowerBound.line) * 1000 + (range.upperBound.character - range.lowerBound.character)
                if rangeSize < smallestRange {
                    smallestRange = rangeSize
                    contextNode = node
                }
            }
        }
        return contextNode
    }
}
