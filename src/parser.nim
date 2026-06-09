import std/algorithm
import std/strformat
import std/strutils
import errors
import lexer
import nodes
import tokens

type Parser = ref object
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
    let (line, col, ctx) = self.lookupPos(self.pos)
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
    return Parser(
        tokens: tokens,
        program: Program(
            source: source,
            lineIndex: lineIndex
        ),
        filename: filename
    )

proc current*(self: Parser): Token {.inline.} =
    self.tokens[self.pos]

proc peek*(self: Parser, offset: int = 1): Token =
    let pos = self.pos + offset
    if pos >= len(self.tokens):
        return self.tokens[^1] # EOF token
    return self.tokens[pos]

proc advance(self: Parser): Token =
    let token = self.current
    self.pos.inc()
    return token

proc expect(self: Parser, kind: TokenType): Token =
    if self.current.kind != kind:
        raise self.error(StarchSyntaxError, fmt"Expected {kind}, got {self.current.kind}")

proc terminate(self: Parser) =
    if self.current.kind != TokenType.semicolon:
        let currentMeta = self.lookupPos(self.current.pos)
        let lastMeta = self.lookupPos(self.peek(-1).pos)
        let meta = if currentMeta.line != lastMeta.line: lastMeta
                   else: currentMeta
        let length = if currentMeta.line != lastMeta.line: self.peek(-1).length
                     else: self.current.length

        raise newStarchError(StarchSyntaxError, fmt"Expected {TokenType.semicolon}", meta.content, meta.line, meta.col, length, self.filename)

    discard self.advance()

proc parse_primary(self: Parser): Node

proc parse_expression(self: Parser): Node =
    return self.parse_primary()

proc parse_primary(self: Parser): Node =
    let token = self.current
    case token.kind:
        of TokenType.number:
            return node(self.advance(), NodeKind.literal,
                literalKind: LiteralKind.int,
                literalValue: token.value.strVal
            )
        of TokenType.float:
            return node(self.advance(), NodeKind.literal,
                literalKind: LiteralKind.float,
                literalValue: token.value.strVal
            )
        of TokenType.string:
            return node(self.advance(), NodeKind.literal,
                literalKind: LiteralKind.string,
                literalValue: token.value.strVal
            )
        of TokenType.bool:
            return node(self.advance(), NodeKind.literal,
                literalKind: LiteralKind.bool,
                boolVal: token.value.boolVal
            )

proc parse_expression_statement(self: Parser): Node =
    let token = self.current
    # LHS
    let expression = self.parse_expression()

    if self.current.kind == TokenType.assign:
        if not (expression.kind in {
            NodeKind.identifier,   # bar = baz
            NodeKind.memberAccess, # foo.bar = baz
            NodeKind.listLiteral,  # [foo, bar] = baz
            NodeKind.dictLiteral,  # {foo, bar} = baz
            NodeKind.tupleLiteral  # (foo, bar) = baz
        }):
            raise self.error(StarchSyntaxError, "invalid assignment target")

        # Consume the = operator
        discard self.advance()
        # RHS
        let value = self.parse_expression()
        self.terminate()
        return node(token, NodeKind.assign,
            assignVariable: expression,
            assignOperator: TokenType.assign,
            assignValue: value
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
        return node(token, NodeKind.assign,
            assignVariable: expression,
            assignOperator: operator,
            assignValue: value
        )

    self.terminate()
    return node(token, NodeKind.expressionStatement, expression: expression)

proc parse_statement(self: Parser): Node =
    case self.current.kind:
        # tbd
        else:
            return self.parse_expression_statement()

proc parse*(self: Parser): Program =
    while self.current.kind != TokenType.eof:
        self.program.statements.add(self.parse_statement())
    return self.program
