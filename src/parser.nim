import errors
import lexer
import nodes
import std/algorithm
import std/strfmt
import tokens

type Parser = ref object
    tokens*: seq[Token]
    program*: Program
    filename*: string
    pos*: int

proc lookupPos(self: Parser, pos: int): tuple[line: int, col: int, content: string] {.inline.} =
    ## Get the text content of the current line.
    # Find the first line index greater than pos, then step back
    let line = self.lines.lineStarts.upperBound(pos) - 1
    let col = (pos - self.lines.lineStarts[line]) + 1 # 1-indexed column
    let ctx = ($self.program.source).splitLines()[line]

    return (line: line + 1, col: col, content: ctx)

proc newParser(tokens: seq[Token], filename: string, source: string, lineIndex: LineIndex): Parser =
    return Parser(
        tokens: tokens,
        program: Program(
            source: source,
            lineIndex: lineIndex
        ),
        filename: filename
    )

proc current*(self: Parser): Token =
    self.tokens[self.pos]

proc peek*(self: Parser, offset: int = 1): Token =
    let pos = self.pos + offset
    if pos >= len(self.tokens):
        return self.tokens[-1] # EOF token
    return self.tokens[pos]

proc advance(self: Parser): Token =
    let token = self.current
    self.pos.inc()
    return token

proc expect(self, kind: TokenType): Token =
    if self.current.kind != kind:
        raise self.error(StarchSyntaxError, fmt"Expected {kind}, got {self.current.kind}")

proc terminate(self) =
	last = self.peek(-1)
	if self.current.kind != TokenType.semicolon:
		if self.current.line != last.line:
			raise StarchSyntaxError(fmt"Expected {TokenType.semicolon}", last.line, last.source_line, len(last.source_line) + 1, self.file)
		else:
			raise self.error(StarchSyntaxError, fmt"Expected {TokenType.semicolon}, got {self.current.kind}")

	self.advance()

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
