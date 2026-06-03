import std/macros
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

    LiteralKind* = enum
        int, float, string, bool

    Node* = ref object
        ## An AST node.
        pos*, length*: int

        case kind*: NodeKind
        of NodeKind.parameter:
            paramName*: string
            paramHint*: Node
            paramDefault*: Node

        of NodeKind.varDeclaration:
            varName*: string
            varHint*: Node
            varValue*: Node
            varMutable*: bool

        of NodeKind.derivedVariable:
            derivedName*: string
            derivedHint*: Node
            derivedValue*: Node
            derivedDependencies*: HashSet[Node]

        of NodeKind.literal:
            case literalKind*: LiteralKind
            of LiteralKind.int:    intVal*: int
            of LiteralKind.float:  floatVal*: float
            of LiteralKind.string: stringVal*: string
            of LiteralKind.bool:   boolVal*: bool

        of NodeKind.listLiteral:
            listElements*: seq[Node]

        of NodeKind.dictLiteral:
            dictPairs*: seq[tuple[key: Node, value: Node]]

        of NodeKind.identifier:
            name*: string

        of NodeKind.functionCall:
            callCallee*: Node
            callArgs*: seq[Node]

        of NodeKind.memberAccess:
            accessObj*: Node
            accessMember*: Node

        of NodeKind.expressionStatement:
            expression*: Node

        of NodeKind.unaryOp:
            unaryOperator*: TokenType
            unaryOperand*: Node

        of NodeKind.binaryOp:
            binaryOperator*: TokenType
            binaryLeft*: Node
            binaryRight*: Node

        of NodeKind.lambda:
            lambdaParams*: seq[Node]
            lambdaBody*: seq[Node]
            lambdaHint*: Node

        of NodeKind.return:
            returnValue*: Node

        of NodeKind.throw:
            throwException*: Node

        of NodeKind.using:
            usingModules*: seq[string]

        of NodeKind.importFrom:
            importModule*: string
            importNames*: seq[string]

        of NodeKind.ifStatement:
            ifBranches*: seq[tuple[condition: Node, body: seq[Node]]]
            ifElseBody*: seq[Node]

        of NodeKind.whileLoop:
            whileCondition*: Node
            whileBody*: seq[Node]

        of NodeKind.forLoop:
            forVariables*: seq[Node]
            forCollection*: Node
            forBody*: seq[Node]

        of NodeKind.watchStatement:
            watchDependencies*: seq[Node]
            watchBody*: seq[Node]

        of NodeKind.assign:
            assignVariable*: Node
            assignValue*: Node

        of NodeKind.functionDeclaration:
            funcName*: string
            funcParams*: seq[Node]
            funcReturnKind*: Node
            funcBody*: seq[Node]

        of NodeKind.matchStatement:
            matchExpression*: Node
            matchCases*: seq[tuple[patterns: seq[Node], body: seq[Node]]]

        of NodeKind.tryStatement:
            tryBody*: seq[Node]
            tryCatches*: seq[tuple[kind: Node, variable: Node, body: seq[Node]]]
            tryFinallyBody*: seq[Node]

        of NodeKind.classDeclaration:
            className*: Node
            classParent*: Node
            classFields*: seq[Node]
            classMethods*: seq[Node]
            classWatchers*: seq[Node]
            classDerivatives*: seq[Node]

        of NodeKind.await:
            awaitExpression*: Node

        of NodeKind.yield:
            yieldExpression*: Node

        of NodeKind.indexAccess:
            indexObj*: Node
            indexMember*: Node

        of NodeKind.ternaryIf:
            ternaryCondition*: Node
            ternaryTrue*: seq[Node]
            ternaryFalse*: seq[Node]

        of NodeKind.comment:
            comment*: string

        of NodeKind.comprehension:
            comprehensionExpr*: Node
            comprehensionVars*: seq[Node]
            comprehensionCollection*: Node
            comprehensionCondition*: Node

        of NodeKind.declarativeObject:
            objFields*: seq[tuple[name: Node, value: Node]]
            objChildren*: seq[Node]

        of NodeKind.typeOptional:
            optionalKind*: Node

        of NodeKind.typeUnion:
            unionKinds*: seq[Node]

        of NodeKind.typeArgument:
            typeArgKind*: Node
            typeArgArgs*: seq[Node]

        else: discard

type Program* = ref object
    ## A collection of statements.
    statements*: seq[Node]

proc treeRepr(node: Node, prefix: string, isLast: bool): string =
    if node == nil: return ""

    let
        connector = if isLast: "└── " else: "├── "
        childPrefix = if isLast: "    " else: "│   "

    proc branch(label: string, children: seq[string], p: string): string =
        result = p & connector & label & "\n"
        for i, child in children:
            result &= child

    proc leaf(label: string): string =
        prefix & connector & label & "\n"

    proc childNode(n: Node, p: string, last: bool): string =
        treeRepr(n, p, last)

    proc childNodes(nodes: seq[Node], p: string): string =
        for i, n in nodes:
            result &= treeRepr(n, p, i == nodes.high)

    proc childSeqStr(label: string, items: seq[string], p: string, last: bool): string =
        let conn = if last: "└── " else: "├── "
        let cp   = if last: "    " else: "│   "
        result = p & conn & label & "\n"
        for i, s in items:
            let lconn = if i == items.high: "└── " else: "├── "
            result &= p & cp & lconn & s & "\n"

    let p = prefix & childPrefix
    let header = prefix & connector

    case node.kind:
    of NodeKind.parameter:
        result = header & "parameter: " & node.paramName & "\n"
        if node.paramHint   != nil: result &= treeRepr(node.paramHint,    p, node.paramDefault == nil)
        if node.paramDefault != nil: result &= treeRepr(node.paramDefault, p, true)

    of NodeKind.varDeclaration:
        result = header & "var" & (if node.varMutable: " (mut)" else: "") & ": " & node.varName & "\n"
        if node.varHint  != nil: result &= treeRepr(node.varHint,  p, node.varValue == nil)
        if node.varValue != nil: result &= treeRepr(node.varValue, p, true)

    of NodeKind.derivedVariable:
        result = header & "derived: " & node.derivedName & "\n"
        if node.derivedHint  != nil: result &= treeRepr(node.derivedHint,  p, node.derivedValue == nil)
        if node.derivedValue != nil: result &= treeRepr(node.derivedValue, p, true)

    of NodeKind.literal:
        result = header & "literal: " & (case node.literalKind
            of LiteralKind.int:    $node.intVal
            of LiteralKind.float:  $node.floatVal
            of LiteralKind.string: "\"" & node.stringVal & "\""
            of LiteralKind.bool:   $node.boolVal) & "\n"

    of NodeKind.listLiteral:
        result = header & "list\n" & childNodes(node.listElements, p)

    of NodeKind.dictLiteral:
        result = header & "dict\n"
        for i, pair in node.dictPairs:
            let last = i == node.dictPairs.high
            let pconn = if last: "└── " else: "├── "
            let pp    = if last: "    " else: "│   "
            result &= p & pconn & "pair\n"
            result &= treeRepr(pair.key,   p & pp, false)
            result &= treeRepr(pair.value, p & pp, true)

    of NodeKind.identifier:
        result = header & "identifier: " & node.name & "\n"

    of NodeKind.functionCall:
        result = header & "call\n"
        result &= treeRepr(node.callCallee, p, node.callArgs.len == 0)
        result &= childNodes(node.callArgs, p)

    of NodeKind.memberAccess:
        result = header & ".\n"
        result &= treeRepr(node.accessObj,    p, false)
        result &= treeRepr(node.accessMember, p, true)

    of NodeKind.expressionStatement:
        result = header & "exprStmt\n"
        result &= treeRepr(node.expression, p, true)

    of NodeKind.unaryOp:
        result = header & "unary: " & $node.unaryOperator & "\n"
        result &= treeRepr(node.unaryOperand, p, true)

    of NodeKind.binaryOp:
        result = header & "binary: " & $node.binaryOperator & "\n"
        result &= treeRepr(node.binaryLeft,  p, false)
        result &= treeRepr(node.binaryRight, p, true)

    of NodeKind.lambda:
        result = header & "lambda\n"
        result &= childNodes(node.lambdaParams, p)
        if node.lambdaHint != nil: result &= treeRepr(node.lambdaHint, p, node.lambdaBody.len == 0)
        result &= childNodes(node.lambdaBody, p)

    of NodeKind.return:
        result = header & "return\n"
        if node.returnValue != nil: result &= treeRepr(node.returnValue, p, true)

    of NodeKind.throw:
        result = header & "throw\n"
        result &= treeRepr(node.throwException, p, true)

    of NodeKind.using:
        result = header & "using\n"
        result &= childSeqStr("modules", node.usingModules, p, true)

    of NodeKind.importFrom:
        result = header & "import from: " & node.importModule & "\n"
        result &= childSeqStr("names", node.importNames, p, true)

    of NodeKind.ifStatement:
        result = header & "if\n"
        for i, branch in node.ifBranches:
            let last = i == node.ifBranches.high and node.ifElseBody.len == 0
            let bconn = if last: "└── " else: "├── "
            let bp    = if last: "    " else: "│   "
            result &= p & bconn & "branch\n"
            result &= treeRepr(branch.condition, p & bp, false)
            result &= childNodes(branch.body,    p & bp)
        if node.ifElseBody.len > 0:
            result &= p & "└── else\n"
            result &= childNodes(node.ifElseBody, p & "    ")

    of NodeKind.whileLoop:
        result = header & "while\n"
        result &= treeRepr(node.whileCondition, p, false)
        result &= childNodes(node.whileBody, p)

    of NodeKind.forLoop:
        result = header & "for\n"
        result &= childNodes(node.forVariables, p)
        result &= treeRepr(node.forCollection, p, false)
        result &= childNodes(node.forBody, p)

    of NodeKind.watchStatement:
        result = header & "watch\n"
        result &= childNodes(node.watchDependencies, p)
        result &= childNodes(node.watchBody, p)

    of NodeKind.assign:
        result = header & "assign\n"
        result &= treeRepr(node.assignVariable, p, false)
        result &= treeRepr(node.assignValue,    p, true)

    of NodeKind.functionDeclaration:
        result = header & "func: " & node.funcName & "\n"
        result &= childNodes(node.funcParams, p)
        if node.funcReturnKind != nil: result &= treeRepr(node.funcReturnKind, p, node.funcBody.len == 0)
        result &= childNodes(node.funcBody, p)

    of NodeKind.matchStatement:
        result = header & "match\n"
        result &= treeRepr(node.matchExpression, p, node.matchCases.len == 0)
        for i, c in node.matchCases:
            let last  = i == node.matchCases.high
            let cconn = if last: "└── " else: "├── "
            let cp2   = if last: "    " else: "│   "
            result &= p & cconn & "case\n"
            result &= childNodes(c.patterns, p & cp2)
            result &= childNodes(c.body,     p & cp2)

    of NodeKind.tryStatement:
        result = header & "try\n"
        result &= childNodes(node.tryBody, p)
        for i, c in node.tryCatches:
            let last  = i == node.tryCatches.high and node.tryFinallyBody.len == 0
            let cconn = if last: "└── " else: "├── "
            let cp2   = if last: "    " else: "│   "
            result &= p & cconn & "catch\n"
            if c.kind     != nil: result &= treeRepr(c.kind,     p & cp2, false)
            if c.variable != nil: result &= treeRepr(c.variable, p & cp2, false)
            result &= childNodes(c.body, p & cp2)
        if node.tryFinallyBody.len > 0:
            result &= p & "└── finally\n"
            result &= childNodes(node.tryFinallyBody, p & "    ")

    of NodeKind.classDeclaration:
        result = header & "class: " & (if node.className != nil: node.className.name else: "?") & "\n"
        if node.classParent != nil: result &= treeRepr(node.classParent, p, false)
        result &= childNodes(node.classFields,      p)
        result &= childNodes(node.classMethods,     p)
        result &= childNodes(node.classWatchers,    p)
        result &= childNodes(node.classDerivatives, p)

    of NodeKind.await:
        result = header & "await\n"
        result &= treeRepr(node.awaitExpression, p, true)

    of NodeKind.yield:
        result = header & "yield\n"
        result &= treeRepr(node.yieldExpression, p, true)

    of NodeKind.indexAccess:
        result = header & "index\n"
        result &= treeRepr(node.indexObj,    p, false)
        result &= treeRepr(node.indexMember, p, true)

    of NodeKind.ternaryIf:
        result = header & "ternary\n"
        result &= treeRepr(node.ternaryCondition, p, false)
        result &= childNodes(node.ternaryTrue,    p)
        result &= childNodes(node.ternaryFalse,   p)

    of NodeKind.comment:
        result = header & "# " & node.comment & "\n"

    of NodeKind.comprehension:
        result = header & "comprehension\n"
        result &= treeRepr(node.comprehensionExpr,       p, false)
        result &= childNodes(node.comprehensionVars,     p)
        result &= treeRepr(node.comprehensionCollection, p, node.comprehensionCondition == nil)
        if node.comprehensionCondition != nil:
            result &= treeRepr(node.comprehensionCondition, p, true)

    of NodeKind.declarativeObject:
        result = header & "object\n"
        for i, field in node.objFields:
            let last  = i == node.objFields.high and node.objChildren.len == 0
            let fconn = if last: "└── " else: "├── "
            let fp    = if last: "    " else: "│   "
            result &= p & fconn & "field\n"
            result &= treeRepr(field.name,  p & fp, false)
            result &= treeRepr(field.value, p & fp, true)
        result &= childNodes(node.objChildren, p)

    of NodeKind.typeOptional:
        result = header & "optional\n"
        result &= treeRepr(node.optionalKind, p, true)

    of NodeKind.typeUnion:
        result = header & "union\n"
        result &= childNodes(node.unionKinds, p)

    of NodeKind.typeArgument:
        result = header & "typeArg\n"
        result &= treeRepr(node.typeArgKind, p, node.typeArgArgs.len == 0)
        result &= childNodes(node.typeArgArgs, p)

    of NodeKind.break:    result = header & "break\n"
    of NodeKind.continue: result = header & "continue\n"
    of NodeKind.setLiteral: result = header & "set\n"
    else: result = header & $node.kind & "\n"

proc `$`*(node: Node): string =
    treeRepr(node, "", true)

proc `$`*(program: Program): string =
    result = "program\n"
    for i, node in program.statements:
        result &= treeRepr(node, "", i == program.statements.high)

macro node*(token: Token, kind: NodeKind, args: varargs[untyped]): Node =
    result = quote do:
        Node(kind: `kind`, pos: `token`.pos, length: `token`.length, `args`)
