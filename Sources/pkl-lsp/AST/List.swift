import Foundation

class ListLiteral: ASTNode {
    var elements: [ASTNode]
    
    init(elements: [ASTNode]) {
        self.elements = elements
        super.init()
    }
}

class ListConcatenation: ASTNode {
    let lists: [ASTNode]
    
    init(lists: [ASTNode]) {
        self.lists = lists
        super.init()
    }
}

class ListAccess: ASTNode {
    let list: ASTNode
    let index: ASTNode
    
    init(list: ASTNode, index: ASTNode) {
        self.list = list
        self.index = index
        super.init()
    }
}

class ListOperation: ASTNode {
    enum OperationType {
        case contains, first, rest, reverse, drop, take, map
    }
    
    let operation: OperationType
    let list: ASTNode
    let argument: ASTNode?
    
    init(operation: OperationType, list: ASTNode, argument: ASTNode? = nil) {
        self.operation = operation
        self.list = list
        self.argument = argument
        super.init()
    }
}

// Usage Examples
// Constructing lists
let emptyList = ListLiteral(elements: [])
let numberList = ListLiteral(elements: [IntLiteral(value: "1"), IntLiteral(value: "2"), IntLiteral(value: "3")])
let heterogenousList = ListLiteral(elements: [IntLiteral(value: "1"), StringLiteral(value: "\"x\""), numberList])

// Concatenating lists
let concatenatedList = ListConcatenation(lists: [numberList, ListLiteral(elements: [IntLiteral(value: "4"), IntLiteral(value: "5")])])

// Accessing a list element
let elementAccess = ListAccess(list: numberList, index: IntLiteral(value: "2"))

// List operations
let containsThree = ListOperation(operation: .contains, list: numberList, argument: IntLiteral(value: "3"))
let firstElement = ListOperation(operation: .first, list: numberList)
let restOfList = ListOperation(operation: .rest, list: numberList)
let reversedList = ListOperation(operation: .reverse, list: numberList)
let droppedFirst = ListOperation(operation: .drop, list: numberList, argument: IntLiteral(value: "1"))
let takenTwo = ListOperation(operation: .take, list: numberList, argument: IntLiteral(value: "2"))
let tripledValues = ListOperation(operation: .map, list: numberList, argument: LambdaExpression(parameters: ["n"], body: BinaryExpression(left: VariableReference(name: "n"), binaryOperator: .multiplication, right: IntLiteral(value: "3"))))

