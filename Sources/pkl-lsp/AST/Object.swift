import Foundation

class PklProperty : ASTNode {
    var name: String
    var value: ASTNode?

    init(name: String, value: ASTNode? = nil) {
        self.name = name
        self.value = value
        super.init()
    }
}

class PklObject : ASTNode {
    var name: String
    var properties: [PklProperty]

    init(name: String, properties: [PklProperty]) {
        self.name = name
        self.properties = properties
        super.init()
    }
}

class PklAmendedObject : PklObject {
    var parent: PklObject

    init(name: String, parent: PklObject) {
        self.parent = parent
        super.init(name: name, properties: parent.properties)
    }
}

class PklClassObject : PklObject {
    var parent: PklClass

    init(name: String, parent: PklClass) {
        self.parent = parent
        var properties = [PklProperty]()
        for property in parent.properties {
            if !property.isHidden {
                properties.append(PklProperty(name: property.name, value: property.type))
            }
        }
        super.init(name: name, properties: properties)
    }
}
