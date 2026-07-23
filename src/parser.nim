import std/algorithm
import std/strformat
import std/strutils
import errors
import lexer
import nodes
import tokens

type Parser = ref object
    ## A STARCH parser. Takes lexed tokens and converts them into an AST.
    tokens*: seq[Token]
    program*: Program
    filename*: string
    pos*: int

proc lookupPos(self: Parser, pos: int): tuple[line: int, col: int, content: string] {.inline.} =
    ## Get the text content of the current line.
    # Find the first line index greater than pos, then step back
    let line = self.program.lineIndex.lineStarts.upperBound(pos) - 1
    let col = (pos - self.program.lineIndex.lineStarts[line]) + 1 # 1-indexed column
    let ctx = ($self.program.source).splitLines()[line]

    return (line: line + 1, col: col, content: ctx)

proc error(self: Parser, kind: typedesc[StarchError], message: string): StarchError =
    ## Generates an error with intelligent position data.
    let (line, col, ctx) = self.lookupPos(self.current.pos)
    return newStarchError(
        kind = kind,
        msg = message,
        context = ctx,
        line = line,
        col = col,
        length = self.current.length,
        file = self.filename
    )

proc newParser*(tokens: seq[Token], filename: string, source: string, lineIndex: LineIndex): Parser =
    ## Creates a parser with default values.
    ## Comment tokens are stripped from the token stream up front and stored in
    ## Program.comments so that all helpers can ignore them entirely.
    var filteredTokens: seq[Token] = @[]
    var comments: seq[Token] = @[]
    for token in tokens:
        if token.kind == TokenType.comment:
            comments.add(token)
        else:
            filteredTokens.add(token)

    return Parser(
        tokens: filteredTokens,
        program: Program(
            source: source,
            lineIndex: lineIndex,
            comments: comments
        ),
        filename: filename
    )

proc current*(self: Parser): Token {.inline.} =
    ## Get the current token
    if self.pos >= len(self.tokens):
        when defined(debug):
            echo ".current oob; returning eof"
        return self.tokens[^1] # EOF
    return self.tokens[self.pos]

proc peek*(self: Parser, offset: int = 1): Token =
    ## Look at token self.pos + offset, without consuming it.
    let pos = self.pos + offset
    if pos >= len(self.tokens):
        when defined(debug):
            echo "peek oob; returning eof"
        return self.tokens[^1] # EOF token
    when defined(debug):
        echo &"peeked {offset}, returning {self.tokens[pos]}"
    return self.tokens[pos]

proc advance(self: Parser): Token =
    ## Advance past the current token, returning it.
    let token = self.current
    when defined(debug):
        echo "advancing past " & $token
    self.pos.inc()
    return token

proc expect(self: Parser, kind: TokenType): Token =
    ## Expect a token and consume it. Raises an error if the token is not expected.
    when defined(debug):
        echo &"validating for token {kind}"
    if self.current.kind != kind:
        raise self.error(StarchSyntaxError, &"expected {kind}, got {self.current.kind}")
    return self.advance()

proc terminate(self: Parser) =
    ## End a statement with a semicolon. Uses intelligent line positioning data for errors.
    when defined(debug):
        echo "=== terminating statement ==="
    if self.current.kind != TokenType.semicolon:
        let currentMeta = self.lookupPos(self.current.pos)
        let lastMeta = self.lookupPos(self.peek(-1).pos)
        let meta = if currentMeta.line != lastMeta.line: lastMeta
                   else: currentMeta
        let length = if currentMeta.line != lastMeta.line: self.peek(-1).length
                     else: self.current.length

        raise newStarchError(StarchSyntaxError, &"expected {TokenType.semicolon}", meta.content, meta.line, meta.col, length, self.filename)

    discard self.advance()

proc is_lambda(self: Parser): bool =
    ## Checks if the next tokens define a lambda function.
    var pos = self.pos + 1 # skip the left paren
    var depth = 1
    while pos < len(self.tokens):
        case self.tokens[pos].kind:
        of TokenType.lParen:
            depth.inc()
        of TokenType.rParen:
            depth.dec()
            if depth == 0:
                # Check bounds before looking ahead
                if pos + 1 < len(self.tokens):
                    return self.tokens[pos + 1].kind == TokenType.fatArrow
                return false
        else: discard
        pos += 1
    return false

# Stubs
proc parse_pipeline(self: Parser): Node
proc parse_unary(self: Parser): Node
proc parse_statement(self: Parser): Node

proc parse_expression(self: Parser): Node =
    ## Parse a STARCH expression.
    when defined(debug):
        echo "=== parsing expr ==="
    return self.parse_pipeline()

proc parse_block(self: Parser): seq[Node] =
    ## Parse several statements wrapped in braces.
    discard self.expect(TokenType.lBrace)
    result = @[]
    while self.current.kind != TokenType.rBrace:
        result.add(self.parse_statement())
    discard self.expect(TokenType.rBrace)

proc parse_type(self: Parser): Node =
    ## Parse a type hint, with support for unions, generics and optional types.
    let token = self.expect(TokenType.ident)
    # Start with the base identifier
    var currentType = node(token, self.peek(-1), NodeKind.identifier, name = token.value.strVal)

    if self.current.kind == TokenType.lBracket:
        # Generic — TypeA[T]
        discard self.advance()
        var parts = @[self.parse_type()]
        while self.current.kind == TokenType.comma:
            discard self.advance()
            parts.add(self.parse_type())
        discard self.expect(TokenType.rBracket)
        # Update currentType instead of returning
        currentType = node(token, self.peek(-1), NodeKind.genericType,
            genericKind = currentType,
            typeArgs = parts
        )

    if self.current.kind == TokenType.question:
        # Optional — TypeB? (equivalent to union with none)
        currentType = node(token, self.advance(), NodeKind.typeOptional, optionalKind = currentType)

    if self.current.kind == TokenType.pipe:
        # Union — TypeC | TypeD | TypeE
        var parts = @[currentType]
        while self.current.kind == TokenType.pipe:
            discard self.advance()
            parts.add(self.parse_type())
        return node(token, self.peek(-1), NodeKind.typeUnion, unionKinds = parts)

    # If not a union, return the current type
    return currentType

proc parse_params(self: Parser): seq[Node] =
    ## Parse parameters in a function definition.
    var params: seq[Node] = @[]
    while self.current.kind != TokenType.rParen:
        let name = self.expect(TokenType.ident)
        var hint: Node = nil
        var default: Node = nil

        if self.current.kind == TokenType.colon: # (x: int)
            discard self.advance()
            hint = self.parse_type()
        if self.current.kind == TokenType.or: # (name or "john")
            discard self.advance()
            default = self.parse_expression()
        params.add(node(name, self.peek(-1), NodeKind.parameter,
            paramName = name.value.strVal,
            paramHint = hint,
            paramDefault = default))
    return params

proc parse_args(self: Parser): seq[Node] =
    ## Parse arguments passed to a function call.
    var args: seq[Node] = @[]
    while self.current.kind != TokenType.rParen:
        args.add(self.parse_expression())
        if self.current.kind == TokenType.comma:
            discard self.advance()
    return args

proc parse_primary(self: Parser): Node =
    ## Parse a primary expression (literals, identifiers, groups and lambdas).
    # TODO: This does not support comprehensions.
    let token = self.current
    case token.kind:
        of TokenType.number:
            discard self.advance()
            return node(token, self.peek(-1), NodeKind.literal,
                literalKind = LiteralKind.int,
                literalValue = token.value.strVal
            )
        of TokenType.float:
            discard self.advance()
            return node(token, self.peek(-1), NodeKind.literal,
                literalKind = LiteralKind.float,
                literalValue = token.value.strVal
            )
        of TokenType.string:
            discard self.advance()
            return node(token, self.peek(-1), NodeKind.literal,
                literalKind = LiteralKind.string,
                literalValue = token.value.strVal
            )
        of TokenType.bool:
            discard self.advance()
            return node(token, self.peek(-1), NodeKind.literal,
                literalKind = LiteralKind.bool,
                boolVal = token.value.boolVal
            )
        of TokenType.ident:
            discard self.advance()
            return node(token, self.peek(-1), NodeKind.identifier,
                name = token.value.strVal
            )
        of TokenType.lParen:
            # () - grouping/lambda
            if self.is_lambda():
                # () => {}
                discard self.advance()
                let params = self.parse_params()
                discard self.expect(TokenType.rParen)
                discard self.expect(TokenType.fatArrow)
                let body = self.parse_block()
                return node(token, self.peek(-1), NodeKind.lambda,
                    lambdaParams = params,
                    lambdaBody = body)
            # (x)
            discard self.advance()
            let expression = self.parse_expression()
            discard self.expect(TokenType.rParen)
            return expression

        of TokenType.lBrace:
            # {} - dict/set literal
            discard self.advance()
            # The next item should be an expression
            # After that, if it's a comma then it's a set,
            # if it's a colon it's a dictionary
            # and if it's a right brace it's a one-item set.
            if self.current.kind == TokenType.rBrace:
                # Empty dict
                return node(token, self.advance(), NodeKind.dictLiteral, dictPairs = @[])

            let first = self.parse_expression()
            case self.current.kind:
            of TokenType.rBrace:
                # One-item set
                discard self.advance()
                return node(token, self.peek(-1), NodeKind.setLiteral, setItems = @[first])
            of TokenType.comma:
                # Set
                discard self.advance() # consume the comma
                var items = @[first]

                while self.current.kind != TokenType.eof:
                    # Support trailing commas
                    if self.current.kind == TokenType.rBrace:
                        break

                    items.add(self.parse_expression())
                    if self.current.kind == TokenType.rBrace:
                        break
                    discard self.expect(TokenType.comma)

                discard self.expect(TokenType.rBrace)
                return node(token, self.peek(-1), NodeKind.setLiteral, setItems = items)
            of TokenType.colon:
                # Dictionary
                discard self.advance() # consume the colon
                let value = self.parse_expression()
                var items = @[(key: first, value: value)]

                while self.current.kind != TokenType.eof:
                    if self.current.kind == TokenType.rBrace:
                        break

                    discard self.expect(TokenType.comma)

                    if self.current.kind == TokenType.rBrace: # support trailing comma
                        break

                    let key = self.parse_expression()

                    discard self.expect(TokenType.colon)
                    items.add((key: key, value: self.parse_expression()))

                discard self.expect(TokenType.rBrace)
                return node(token, self.peek(-1), NodeKind.dictLiteral, dictPairs = items)
            else:
                raise self.error(StarchSyntaxError, &"unexpected token {self.current} in dict/set literal")

        of TokenType.lBracket:
            # [] — list literal
            discard self.advance()

            var items: seq[Node] = @[]
            while self.current.kind != TokenType.eof:
                if self.current.kind == TokenType.rBracket:
                    break

                items.add(self.parse_expression())
                if self.current.kind == TokenType.rBracket:
                    break
                discard self.expect(TokenType.comma)

            discard self.expect(TokenType.rBracket)
            return node(token, self.peek(-1), NodeKind.listLiteral, listElements = items) # "elements" is kinda inconsistent why is it elements with a list but items with a set??? whatever bro
        else:
            raise self.error(StarchSyntaxError, &"unexpected token {token.kind}")

proc parse_call_or_access(self: Parser): Node =
    ## Parse a call or member access (function calls, indexes and dot notation).
    let start = self.current
    var expression = self.parse_primary()

    while true:
        case self.current.kind:
            of TokenType.lParen:
                # Function call
                discard self.advance()
                let args = self.parse_args()
                discard self.expect(TokenType.rParen)
                expression = node(start, self.peek(-1), NodeKind.functionCall, callCallee = expression, callArgs = args)

            of TokenType.lBracket:
                # Index access
                discard self.advance()
                var isSlice = false
                var index, stop, step: Node

                # Slot 1: Start/Index
                if not (self.current.kind in {TokenType.colon, TokenType.rBracket}):
                    index = self.parse_expression()

                # Slot 2: Stop
                if self.current.kind == TokenType.colon:
                    isSlice = true
                    discard self.advance()

                    if not (self.current.kind in {TokenType.colon, TokenType.rBracket}):
                        stop = self.parse_expression()

                # Slot 3: Step
                if self.current.kind == TokenType.colon:
                    discard self.advance()
                    if self.current.kind == TokenType.rBracket:
                        raise self.error(StarchSyntaxError, "expected expression")

                    step = self.parse_expression()

                discard self.expect(TokenType.rBracket)
                if isSlice and index == nil and stop == nil and step == nil:
                    raise self.error(StarchSyntaxError, "no slice values specified")

                if isSlice:
                    expression = node(start, self.peek(-1), NodeKind.slice, sliceObj = expression, sliceStart = index, sliceStop = stop, sliceStep = step)
                else:
                    expression = node(start, self.peek(-1), NodeKind.indexAccess, indexObj = expression, indexMember = index)

            of TokenType.dot:
                # Member access
                discard self.advance()
                let member = self.parse_expression()
                expression = node(start, self.peek(-1), NodeKind.memberAccess, accessObj = expression, accessMember = member)
            else:
                return expression

proc parse_exponent(self: Parser): Node =
    ## Parse an exponent.
    let base = self.parse_call_or_access()
    if self.current.kind == TokenType.caret:
        let token = self.advance()
        let exponent = self.parse_unary()
        return node(token, self.peek(-1), NodeKind.binaryOp,
            binaryOperator = token.kind,
            binaryLeft = base,
            binaryRight = exponent
        )
    return base

proc parse_unary(self: Parser): Node =
    ## Parse a unary (prefix) operation.
    let token = self.current
    if token.kind in {TokenType.minus, TokenType.bang, TokenType.await, TokenType.yield}:
        discard self.advance()
        let operand = self.parse_unary()
        return node(token, self.peek(-1), NodeKind.unaryOp, unaryOperator = token.kind, unaryOperand = operand)

    return self.parse_exponent()

proc parse_multiplicative(self: Parser): Node =
    ## Parse a multiplicative operation (*, /).
    var left = self.parse_unary()

    while self.current.kind in {TokenType.star, TokenType.slash, TokenType.percent}:
        let token = self.current
        let operator = self.advance().kind
        let right = self.parse_unary()
        left = node(token, self.peek(-1), NodeKind.binaryOp,
            binaryOperator = operator,
            binaryLeft = left,
            binaryRight = right
        )
    return left

proc parse_additive(self: Parser): Node =
    ## Parse an additive operation (+, -).
    var left = self.parse_multiplicative()

    while self.current.kind in {TokenType.plus, TokenType.minus}:
        let token = self.current
        let operator = self.advance().kind
        let right = self.parse_multiplicative()
        left = node(token, self.peek(-1), NodeKind.binaryOp,
            binaryOperator = operator,
            binaryLeft = left,
            binaryRight = right
        )
    return left

proc parse_range(self: Parser): Node =
    ## Parse the range operator (..).
    let token = self.current
    let left = self.parse_additive()

    if self.current.kind == TokenType.range:
        discard self.advance()
        let right = self.parse_additive()
        return node(token, self.peek(-1), NodeKind.binaryOp,
            binaryOperator = TokenType.range,
            binaryLeft = left,
            binaryRight = right
        )
    return left

proc parse_concat(self: Parser): Node =
    ## Parse the concatenation operator (x ~ y).
    let token = self.current
    var left = self.parse_range()

    while self.current.kind == TokenType.concat:
        discard self.advance()
        let right = self.parse_range()
        left = node(token, self.peek(-1), NodeKind.binaryOp,
            binaryOperator = TokenType.concat,
            binaryLeft = left,
            binaryRight = right
        )

    return left

proc parse_comparison(self: Parser): Node =
    ## Parse comparative operators (<, >).
    let token = self.current
    var left = self.parse_concat()

    while self.current.kind in {
        TokenType.gt, TokenType.gte, TokenType.lt,
        TokenType.lte, TokenType.in, TokenType.notIn
    }:
        let operator = self.advance().kind
        let right = self.parse_concat()
        left = node(token, self.peek(-1), NodeKind.binaryOp,
            binaryOperator = operator,
            binaryLeft = left,
            binaryRight = right
        )
    return left

proc parse_equality(self: Parser): Node =
    ## Parse equality operators (==, is).
    let token = self.current
    var left = self.parse_comparison()

    while self.current.kind in {
        TokenType.eq, TokenType.neq, TokenType.approx,
        TokenType.is, TokenType.isNot
    }:
        let operator = self.advance().kind
        let right = self.parse_comparison()
        left = node(token, self.peek(-1), NodeKind.binaryOp,
            binaryOperator = operator,
            binaryLeft = left,
            binaryRight = right
        )
    return left

proc parse_and(self: Parser): Node =
    ## Parse the and operator (&&).
    let token = self.current
    var left = self.parse_equality()

    while self.current.kind == TokenType.and:
        discard self.advance()
        let right = self.parse_equality()
        left = node(token, self.peek(-1), NodeKind.binaryOp,
            binaryOperator = TokenType.and,
            binaryLeft = left,
            binaryRight = right
        )
    return left

proc parse_or(self: Parser): Node =
    ## Parse the or operator (||).
    let token = self.current
    var left = self.parse_and()

    while self.current.kind == TokenType.or:
        discard self.advance()
        let right = self.parse_and()
        left = node(token, self.peek(-1), NodeKind.binaryOp,
            binaryOperator = TokenType.or,
            binaryLeft = left,
            binaryRight = right
        )
    return left

proc parse_ternary(self: Parser): Node =
    ## Parse the ternary if operator (condition ? true : false)
    let token = self.current
    var condition = self.parse_or()

    if self.current.kind == TokenType.question:
        discard self.advance()
        let trueBranch = self.parse_expression()
        discard self.expect(TokenType.colon)
        let falseBranch = self.parse_ternary()
        condition = node(token, self.peek(-1), NodeKind.ternaryIf,
            ternaryCondition = condition,
            ternaryTrue = trueBranch,
            ternaryFalse = falseBranch
        )
    return condition

proc parse_pipeline(self: Parser): Node =
    ## Parse the pipeline operator (~>)
    let token = self.current
    var left = self.parse_ternary()

    while self.current.kind == TokenType.pipeline:
        discard self.advance()
        let right = self.parse_ternary()
        left = node(token, self.peek(-1), NodeKind.binaryOp,
            binaryOperator = TokenType.pipeline,
            binaryLeft = left,
            binaryRight = right
        )
    return left

proc parse_var_decl(self: Parser): Node =
    ## Parse a variable declaration.
    let token = self.advance()
    let name = self.parse_primary()
    var hint: Node = nil
    var value: Node = nil

    if name.kind notin {
        NodeKind.identifier,  # var x = 0;
        NodeKind.listLiteral, # var [a, b] = [1, 2]
        NodeKind.dictLiteral, # var {value: target} = {"name": "John"}
        NodeKind.setLiteral   # var {a, b} = {"a": 1, "b": 2}
    }:
        raise self.error(StarchSyntaxError, "invalid target for variable declaration")

    if self.current.kind == TokenType.colon:
        discard self.advance()
        hint = self.parse_type()

    if self.current.kind == TokenType.assign:
        discard self.advance()
        value = self.parse_expression()

    self.terminate()
    return node(token, self.peek(-1), NodeKind.varDeclaration,
        varName = name,
        varHint = hint,
        varValue = value,
        varMutable = token.kind == TokenType.var
    )

proc parse_expression_statement(self: Parser): Node =
    ## Parse an ExpressionStatement or Assignment node.
    let token = self.current
    # LHS
    let expression = self.parse_expression()

    if self.current.kind == TokenType.assign:
        if not (expression.kind in {
            NodeKind.identifier,   # bar = baz
            NodeKind.memberAccess, # foo.bar = baz
            NodeKind.listLiteral,  # [foo, bar] = baz
            NodeKind.dictLiteral,  # {foo: bar} = baz
            NodeKind.setLiteral    # {foo, bar} = baz
        }):
            raise self.error(StarchSyntaxError, "invalid assignment target")

        # Consume the = operator
        discard self.advance()
        # RHS
        let value = self.parse_expression()
        self.terminate()
        return node(token, self.peek(-1), NodeKind.assign,
            assignVariable = expression,
            assignOperator = TokenType.assign,
            assignValue = value
        )

    if self.current.kind in {
        TokenType.plusAssign,
        TokenType.minusAssign,
        TokenType.starAssign,
        TokenType.slashAssign
    }:
        if not (expression.kind in {NodeKind.identifier, NodeKind.memberAccess}):
            raise self.error(StarchSyntaxError, "invalid assignment target")

        let operator = case self.advance().kind:
            of TokenType.plusAssign: TokenType.plus
            of TokenType.minusAssign: TokenType.minus
            of TokenType.starAssign: TokenType.star
            of TokenType.slashAssign: TokenType.slash
            else: TokenType.eof # unreachable

        let value = self.parse_expression()
        self.terminate()
        # Gets desugared later
        return node(token, self.peek(-1), NodeKind.assign,
            assignVariable = expression,
            assignOperator = operator,
            assignValue = value
        )

    self.terminate()
    return node(token, self.peek(-1), NodeKind.expressionStatement, expression = expression)

proc parse_statement(self: Parser): Node =
    ## Parse a statement.
    case self.current.kind:
        of TokenType.var, TokenType.const:
            return self.parse_var_decl()
        else:
            return self.parse_expression_statement()

proc parse*(self: Parser): Program =
    ## Parse the program.
    while self.current.kind != TokenType.eof:
        self.program.statements.add(self.parse_statement())
    when defined(debug):
        echo "---"
    return self.program
