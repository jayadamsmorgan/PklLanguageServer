import Foundation

class GlobPattern: ASTNode {
    let pattern: String
    
    init(pattern: String) {
        self.pattern = pattern
        super.init()
    }
}

class Wildcard: ASTNode {
    let type: WildcardType
    
    init(type: WildcardType) {
        self.type = type
        super.init()
    }
    
    enum WildcardType {
        case singleCharacter // ?
        case anyCharacters // *
        case anyCharactersAcrossDirectories // **
    }
}

class CharacterClass: ASTNode {
    let characters: String
    let negated: Bool
    
    init(characters: String, negated: Bool = false) {
        self.characters = characters
        self.negated = negated
        super.init()
    }
}

class SubPattern: ASTNode {
    let patterns: [GlobPattern]
    
    init(patterns: [GlobPattern]) {
        self.patterns = patterns
        super.init()
    }
}

class EscapeSequence: ASTNode {
    let character: String
    
    init(character: String) {
        self.character = character
        super.init()
    }
}
