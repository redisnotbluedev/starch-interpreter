import std/sets
import tokens

type
    NodeKind* {.pure.} = enum
        parameter, varDeclaration, derivedVariable, literal,
        listLiteral, dictLiteral, setLiteral, identifier,
        functionCall, memberAccess, expressionStatement,
        unaryOp, binaryOp, lambda, `break`, `continue`, `return`,
        throw, `using`, importFrom, ifStatement, whileLoop,
        forLoop, watchStatement, assign, functionDeclaration,
        matchStatement, tryStatement, classDeclaration, await,
        `yield`, indexAccess, ternaryIf, comment, comprehension,
        declarativeObject, typeOptional, typeUnion, typeArgument

    # Because of performance, traditional OOP is out of the picture.
    # Nim has object variants just for this, which allows
    # different fields depending on a specific value.
    # But they can't be the same. So a NodeKind.parameter and a
    # NodeKind.varDeclaration which share name and hint? They can't
    # have the same name. So instead we nest everything and
    # have one data field per kind.
    # Thanks, Nim!

    Parameter* = object
        name*: string
        hint*, default*: Node

    VarDeclaration* = object
        name*: string
        hint*: Node
        value*: Node
        mutable*: bool

    DerivedVariable* = object
        name*: string
        hint*: Node
        value*: Node
        dependencies*: HashSet[Node]

    LiteralKind* = enum
        int, float, string, bool

    ListLiteral* = object
        elements*: seq[Node]

    DictLiteral* = object
        pairs*: seq[tuple[key: Node, value: Node]]

    FunctionCall* = object
        callee*: Node
        args*: seq[Node]

    MemberAccess* = object
        obj*: Node
        member*: Node # where kind == NodeKind.identifier

    UnaryOp* = object
        operator*: TokenType
        operand*: Node

    BinaryOp* = object
        operator*: TokenType
        left*: Node
        right*: Node

    Lambda* = object
        params*: seq[Node] # where kind == NodeKind.parameter
        body*: seq[Node]
        hint*: Node

    ImportFrom* = object
        module*: string
        names*: seq[string]

    IfStatement* = object
        branches*: seq[tuple[condition: Node, body: seq[Node]]]
        elseBody*: seq[Node]

    WhileLoop* = object
        condition*: Node
        body*: seq[Node]

    ForLoop* = object
        variables*: seq[Node] # where kind == NodeKind.identifier
        collection*: Node
        body*: seq[Node]

    WatchStatement* = object
        dependencies*: seq[Node]
        body*: seq[Node]

    Assign* = object
        variable*: Node
        value*: Node

    FunctionDeclaration* = object
        name*: string
        params*: seq[Node] # where kind == NodeKind.parameter
        returnKind*: Node
        body*: seq[Node]

    MatchStatement* = object
        expression*: Node
        cases*: seq[tuple[patterns: seq[Node], body: seq[Node]]]

    TryStatement* = object
        body*: seq[Node]
        catches*: seq[tuple[kind: Node, variable: Node, body: seq[Node]]]
        finallyBody*: seq[Node]

    ClassStatement* = object
        name*: Node # where kind == NodeKind.identifier
        parent*: Node
        fields*: seq[Node] # where kind == NodeKind.varDeclaration
        methods*: seq[Node] # where kind == NodeKind.functionDeclaration
        watchers*: seq[Node] # where kind == NodeKind.watchStatement
        derivatives*: seq[Node] # where kind == NodeKind.derivedVariable

    IndexAccess* = object
        obj*: Node
        member*: Node # where kind == NodeKind.identifier

    TernaryIf* = object
        condition*: Node
        trueBody*: seq[Node]
        falseBody*: seq[Node]

    Comprehension* = object
        expression*: Node
        variables*: seq[Node] # where kind == NodeKind.identifier
        collection*: Node
        condition*: Node

    DeclarativeObject* = object
        fields*: seq[tuple[name: Node, value: Node]] # where kind == NodeKind.identifier
        children*: seq[Node]

    TypeOptional* = object
        kind*: Node

    TypeUnion* = object
        kinds*: seq[Node]

    TypeArgument* = object
        kind*: Node
        args*: seq[Node]

    Node* = ref object
        ## An AST node.
        pos*, length*: int

        case kind*: NodeKind
        of NodeKind.parameter:           parameter*: Parameter
        of NodeKind.varDeclaration:      variable*: VarDeclaration
        of NodeKind.derivedVariable:     derived*: DerivedVariable
        of NodeKind.literal:
            case literalKind*: LiteralKind
            of LiteralKind.int:          intVal*: int
            of LiteralKind.float:        floatVal*: float
            of LiteralKind.string:       stringVal*: string
            of LiteralKind.bool:         boolVal*: bool
        of NodeKind.listLiteral:         list*: ListLiteral
        of NodeKind.dictLiteral:         dict*: DictLiteral
        of NodeKind.identifier:          name*: string
        of NodeKind.functionCall:        call*: FunctionCall
        of NodeKind.memberAccess:        access*: MemberAccess
        of NodeKind.expressionStatement: expression*: Node
        of NodeKind.unaryOp:             unary*: UnaryOp
        of NodeKind.binaryOp:            binary*: BinaryOp
        of NodeKind.lambda:              lambda*: Lambda
        of NodeKind.return:              value*: Node
        of Nodekind.throw:               exception*: Node
        of NodeKind.using:               modules*: seq[string]
        of NodeKind.importFrom:          imports*: ImportFrom
        of NodeKind.ifStatement:         conditional*: IfStatement
        of NodeKind.whileLoop:           whileLoop*: WhileLoop
        of NodeKind.forLoop:             forLoop*: ForLoop
        of NodeKind.watchStatement:      watch*: WatchStatement
        of NodeKind.assign:              assignment*: Assign
        of NodeKind.functionDeclaration: function*: FunctionDeclaration
        of NodeKind.matchStatement:      matches*: MatchStatement
        of NodeKind.tryStatement:        attempt*: TryStatement
        of NodeKind.classDeclaration:    class*: ClassStatement
        of NodeKind.await:               awaitExpression*: Node
        of NodeKind.yield:               yieldExpression*: Node
        of NodeKind.indexAccess:         index*: IndexAccess
        of NodeKind.ternaryIf:           ternary*: TernaryIf
        of NodeKind.comment:             comment*: string
        of NodeKind.comprehension:       comprehension*: Comprehension
        of NodeKind.declarativeObject:   obj*: DeclarativeObject
        of NodeKind.typeOptional:        optional*: TypeOptional
        of NodeKind.typeUnion:           union*: TypeUnion
        of NodeKind.typeArgument:        arguments*: TypeArgument
        else:                            discard

type Program* = ref object
    ## A collection of statements.
    statements*: seq[Node]
