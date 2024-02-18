import Foundation

class RegexLiteral: ASTNode {
    let pattern: String
    
    init(pattern: String) {
        self.pattern = pattern
        super.init()
    }
}

class StringMatchesRegex: ASTNode {
    let string: ASTNode
    let regex: ASTNode
    
    init(string: ASTNode, regex: ASTNode) {
        self.string = string
        self.regex = regex
        super.init()
    }
}

class RegexFindMatches: ASTNode {
    let regex: ASTNode
    let string: ASTNode
    
    init(regex: ASTNode, string: ASTNode) {
        self.regex = regex
        self.string = string
        super.init()
    }
}

class MapRegexMatch: ASTNode {
    let matches: ASTNode
    let mapFunction: LambdaExpression
    
    init(matches: ASTNode, mapFunction: LambdaExpression) {
        self.matches = matches
        self.mapFunction = mapFunction
        super.init()
    }
}

// Usage Examples
// Constructing a regex literal
let emailRegex = RegexLiteral(pattern: #"([\w\.]+)@([\w\.]+)"#)

// Testing if a string fully matches a regex
let stringMatches = StringMatchesRegex(
    string: StringLiteral(value: "pigeon@example.com"),
    regex: emailRegex
)

// Finding all matches of a regex in a string
let findAllMatches = RegexFindMatches(
    regex: emailRegex,
    string: StringLiteral(value: "pigeon@example.com / falcon@example.com / parrot@example.com")
)

