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

    public static func allEndNodes(node: any ASTNode, importDepth: Int? = nil) -> [any ASTNode] {
        var nodes = [any ASTNode]()
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

    public static func allEndNodes<T: ASTNode>(node: any ASTNode, importDepth: Int? = nil) -> [T] {
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

    public static func allNodes(node: any ASTNode, importDepth: Int? = nil) -> [any ASTNode] {
        var nodes = [any ASTNode]()
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

    public static func allNodes<T: ASTNode>(node: any ASTNode, importDepth: Int? = nil) -> [T] {
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

    static func enumerate(node: inout any ASTNode, block: (inout any ASTNode) -> Void) {
        block(&node)
        if let children = node.children {
            for var child in children {
                enumerate(node: &child, block: block)
            }
        }
    }

    static func enumerate(node: inout any ASTNode, block: (inout any ASTNode) async -> Void) async {
        await block(&node)
        if let children = node.children {
            for var child in children {
                await enumerate(node: &child, block: block)
            }
        }
    }

    static func enumerate(node: any ASTNode, block: (any ASTNode) -> Void) {
        block(node)
        if let children = node.children {
            for child in children {
                enumerate(node: child, block: block)
            }
        }
    }

    static func enumerate(node: any ASTNode, block: (any ASTNode) async -> Void) async {
        await block(node)
        if let children = node.children {
            for child in children {
                await enumerate(node: child, block: block)
            }
        }
    }

    static func getPositionContext(module: any ASTNode, position: Position) -> (any ASTNode)? {
        allEndNodes(node: module, importDepth: 0).first { node in
            if node.range.positionRange.lowerBound.line > position.line {
                return false
            }
            if node.range.positionRange.upperBound.line < position.line {
                return false
            }
            if node.range.positionRange.lowerBound.character / 2 > position.character {
                return false
            }
            if node.range.positionRange.upperBound.character / 2 < position.character {
                return false
            }
            return true
        }
    }
}
