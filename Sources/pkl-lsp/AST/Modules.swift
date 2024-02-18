import Foundation

class ModuleDeclaration: ASTNode {
    let name: String
    var properties: [Property] = []
    var methods: [MethodDeclaration] = []
    var imports: [ModuleImport] = []
    var amendments: [ModuleAmendment] = []
    var extensions: [ModuleExtension] = []
    
    init(name: String) {
        self.name = name
        super.init()
    }
}

class ModuleImport: ASTNode {
    let uri: String
    let alias: String?
    
    init(uri: String, alias: String? = nil) {
        self.uri = uri
        self.alias = alias
        super.init()
    }
}

class ModuleAmendment: ASTNode {
    let baseModuleUri: String
    var amendments: [Property] = []
    
    init(baseModuleUri: String) {
        self.baseModuleUri = baseModuleUri
        super.init()
    }
}

class ModuleExtension: ASTNode {
    let baseModuleUri: String
    var extensions: [Property] = []
    
    init(baseModuleUri: String) {
        self.baseModuleUri = baseModuleUri
        super.init()
    }
}

// Usage Examples
// Module Declaration with Properties and Method
let birdModule = ModuleDeclaration(name: "Bird")
//birdModule.properties.append(Property(name: "name", value: StringLiteral(value: "Common wood pigeon")))
// birdModule.methods.append(MethodDeclaration(
//     name: "greet",
//     returnType: "String",
//     parameters: [MethodParameter(name: "bird", type: "Bird")],
//     body: StringInterpolation(parts: [
//         StringLiteral(value: "Hello, "),
//         VariableReference(name: "bird.name")
//     ])
// ))

// Importing another module
// birdModule.imports.append(ModuleImport(uri: "com.animals.Taxonomy"))

// Amending a module
let parrotModule = ModuleAmendment(baseModuleUri: "com.animals.Bird")
// parrotModule.amendments.append(Property(name: "name", value: StringLiteral(value: "Parrot")))

// Extending a module
let parrotExtendedModule = ModuleExtension(baseModuleUri: "com.animals.Bird")
// parrotExtendedModule.extensions.append(Property(name: "diet", value: StringLiteral(value: "Berries")))

