import Foundation

class PklClassProperty : ASTNode {

    var name: String
    var type: ASTNode
    var isHidden: Bool

    init(name: String, type: ASTNode, isHidden: Bool = false) {
        self.name = name
        self.type = type
        self.isHidden = isHidden
        super.init()
    }
}

class PklClass : ASTNode {
    var name: String
    var properties: [PklClassProperty]

    init(name: String, properties: [PklClassProperty]) {
        self.name = name
        self.properties = properties
        super.init()
    }
}
