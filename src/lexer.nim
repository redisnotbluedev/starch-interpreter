import errors
import std/strformat
import std/strutils
import std/unicode
import tokens
import unicode_tables

# Shorthands for constructing values
proc toValue*(v: string): TokenValue = TokenValue(kind: ValueKind.string, strVal: v)
proc toValue*(v: int): TokenValue    = TokenValue(kind: ValueKind.int, intVal: v)
proc toValue*(v: float): TokenValue  = TokenValue(kind: ValueKind.float, floatVal: v)
proc toValue*(v: bool): TokenValue   = TokenValue(kind: ValueKind.bool, boolVal: v)
const noValue* = TokenValue(kind: ValueKind.none)
template u*(s: static string): Rune = s.runeAt(0)
proc isAsciiIn(r: Rune, s: set[char]): bool {.inline.} =
    ## Safely checks if a Rune is an ASCII character within a specific set
    let i = r.int
    return i >= 0 and i < 128 and char(i) in s

type Lexer* = ref object
    ## A STARCH lexer. Processes raw STARCH code and outputs a sequence of Tokens.
    code*: seq[Rune]
    filename*: string
    pos*, line*, col*, startCol*, startPos*: int
    tokens*: seq[Token]

proc newLexer*(code: string, filename: string = "<starch-input>"): Lexer =
    ## Creates a Lexer with default values.
    let runes: seq[Rune] = code.toRunes()
    result = Lexer(
        code: runes,
        filename: filename,
        pos: 0,
        line: 1,
        col: 1,
        startCol: 1,
        tokens: @[]
    )

proc peek(self: Lexer, offset: int = 0): Rune {.inline.} =
    ## Look at the next token with an offset, without consuming it.
    if self.pos + offset >= self.code.len:
        return Rune('\0')
    return self.code[self.pos + offset]

proc advance(self: Lexer): Rune {.inline.} =
    ## Consume the next token and return it.
    result = self.code[self.pos]
    self.pos.inc()

    if result == Rune('\n'):
        self.line.inc()
        self.col = 1
    else:
        self.col.inc()

proc getLine(self: Lexer): string {.inline.} =
    ## Get the text content of the current line.
    let lines = ($self.code).splitLines()
    if self.line <= lines.len:
        return lines[self.line - 1] # line is 1-indexed

proc error(self: Lexer, kind: typedesc[StarchError], message: string): StarchError {.inline.} =
    ## Create an error. Automatically fills with position data.
    return newStarchError(
        kind = kind,
        msg = message,
        context = self.get_line(),
        line = self.line,
        col = self.startCol,
        length = self.pos - self.startPos,
        file = self.filename
    )

proc token(self: Lexer, kind: TokenType, value: TokenValue = noValue): Token {.inline.} =
    ## Create a token. Automatically fills with position data.
    return Token(
        kind: kind,
        value: value,
        line: self.line,
        col: self.startCol,
        length: self.pos - self.startPos
    )

proc skipWhitespace(self: Lexer): void =
    ## Consumes whitespace and comments.
    while self.peek() != Rune('\0'):
        # Ignore whitespace
        if self.peek().isAsciiIn({' ', '\n', '\t', '\r'}):
            discard self.advance()
        elif self.peek() == u"/":
            if self.peek(1) == u"/":
                # Starts with "//"
                var comment = ""
                discard self.advance()
                discard self.advance()

                while self.peek() != Rune('\0') and self.peek() != Rune('\n'):
                    comment.add(self.advance())
                self.tokens.add(self.token(TokenType.comment, toValue(comment)))
            elif self.peek(1) == u"*":
                # Starts with /*
                discard self.advance()
                discard self.advance()

                var finished = false
                var comment = ""
                # Consume until "*/"
                while self.peek() != Rune('\0'):
                    if self.peek() == u"*" and self.peek(1) == u"/":
                        discard self.advance()
                        discard self.advance()
                        finished = true
                        break
                    comment.add(self.advance())
                if not finished:
                    raise self.error(StarchSyntaxError, "unterminated block comment")
                self.tokens.add(self.token(TokenType.comment, toValue(comment)))
            else:
                break
        else:
            break

proc readString(self: Lexer): Token =
    ## Consume a string, including escape sequences, and return the resulting token.
    let endingQuote = if self.advance() == u"“": u"”" # HELL YEAH WE SUPPORTING MOBILE DEVELOPERS
                      else: Rune('"')
    var text = ""
    var finished = false

    while self.peek() != Rune('\0'):
        if self.peek() == u"\":
            discard self.advance()
            case self.peek():
                of u"n":
                    discard self.advance()
                    text.add("\n")
                of u"t":
                    discard self.advance()
                    text.add("\t")
                of u"\":
                    discard self.advance()
                    text.add("\\")
                else:
                    if self.peek() == endingQuote:
                        text.add($self.advance())
                    else:
                        # Override the token boundaries to only highlight from here onwards
                        self.startPos = self.pos - 1
                        self.startCol = self.col - 1
                        # Consume the invalid character (instead of peeking) so it's highlighted
                        raise self.error(StarchSyntaxError, &"invalid escape sequence '\\{self.advance()}'")
                        # What's that? You think this is a hacky solution?
                        # Too bad. Be grateful I put comments here.
        elif self.peek() == endingQuote:
            discard self.advance()
            finished = true
            break
        elif self.peek() == Rune('\n'):
            break
        else:
            text.add(self.advance())

    if not finished:
        var message = "unterminated string literal"
        if endingQuote == u"”":
            message.add(". Perhaps you tried to close with a straight quote ('\"') instead of a smart quote ('”')?")
        raise self.error(StarchSyntaxError, message)

    return self.token(TokenType.string, toValue(text))

# Stub it so the compiler understands it
proc readToken(self: Lexer): Token

proc readTemplate(self: Lexer): Token =
    ## Read a template string — these allow multiple lines and interpolation with ${}, but no escape sequences.
    let startLine = self.line
    let startCol = self.col
    let startCtx = self.get_line()
    let startPos = self.pos

    var text = ""
    var finished = false
    var kind = TokenType.templateStart

    discard self.advance() # Eat the starting backtick

    while self.peek() != Rune('\0'):
        if self.peek() == u"$" and self.peek(1) == u"{":
            discard self.advance()
            discard self.advance()

            self.tokens.add(Token(
                kind: kind,
                value: toValue(text),
                line: startLine,
                col: startCol,
                length: self.pos - startPos
            ))
            text = ""
            kind = TokenType.templateMiddle

            var depth = 0 # Track brace depth — when this reaches -1, we've finished the interpolation
            while self.pos < self.code.len and depth >= 0:
                # Exactly the same as the Lexer.lex() loop
                self.startCol = self.col
                self.startPos = self.pos
                self.skipWhitespace()

                if self.pos >= self.code.len:
                    break

                self.startCol = self.col
                self.startPos = self.pos
                let token = self.readToken()
                case token.kind:
                    of TokenType.lBrace: # {
                        depth += 1
                    of TokenType.rBrace: # }
                        depth -= 1
                    else: discard

                self.tokens.add(token)

        elif self.peek() == u"`":
            discard self.advance()
            finished = true
            break
        else:
            text.add(self.advance())

    if not finished:
        raise newStarchError(StarchSyntaxError, "invalid template string literal", startCtx, startLine, startCol, 1, self.filename)

    return Token(
        kind: TokenType.templateEnd,
        value: toValue(text),
        line: startLine,
        col: startCol,
        length: self.pos - startPos
    )

proc readNumber(self: Lexer): Token =
    ## Consume a number, while computing syntax such as 0x[...]), and return the resulting token.
    var num = ""
    var isFloat = false

    let p = self.peek(1).toLower()
    if self.peek() == u"0" and p.isAsciiIn({'x', 'o', 'b'}):
        num.add(self.advance())
        let next = self.advance()
        num.add(next)

        case next:
            of u"x":
                # Hex
                while self.peek().isAsciiIn({'0'..'9', 'a'..'f', 'A'..'F', '_'}):
                    num.add(self.advance())
                if num == "":
                    raise self.error(StarchSyntaxError, "invalid hexadecimal literal")
                return self.token(TokenType.number, toValue(num))
            of u"o":
                # Octal
                while self.peek().isAsciiIn({'0'..'7', '_'}):
                    num.add(self.advance())
                if num == "":
                    raise self.error(StarchSyntaxError, "invalid octal literal")
                return self.token(TokenType.number, toValue(num))
            of u"b":
                # Binary
                while self.peek().isAsciiIn({'0', '1', '_'}):
                    num.add(self.advance())
                return self.token(TokenType.number, toValue(num))
            else:
                discard

    while self.peek().isAsciiIn({'0'..'9', '_'}):
        num.add(self.advance())

    if self.peek() == u"." and self.peek(1).isAsciiIn({'0'..'9', '_'}):
        # Float literal
        isFloat = true
        num.add(self.advance())

        while self.peek().isAsciiIn({'0'..'9', '_'}):
            num.add(self.advance())

    if self.peek().isAsciiIn({'e', 'E'}):
        # Scientific notation
        isFloat = true

        num.add(self.advance())
        if self.peek().isAsciiIn({'-', '+'}):
            num.add(self.advance())

        if not self.peek().isAsciiIn({'0'..'9', '_'}):
            raise self.error(StarchSyntaxError, "invalid component in scientific notation literal")
        while self.peek().isAsciiIn({'0'..'9'}):
            num.add(self.advance())

    if isFloat:
        return self.token(TokenType.number, toValue(num))
    return self.token(TokenType.number, toValue(num))

proc readIdentOrKeyword(self: Lexer): Token =
    var ident = ""
    while self.peek().isXIDContinue():
        ident.add(self.advance())

    # Reserved keywords
    let kind = case ident:
        of "var":      TokenType.var
        of "const":    TokenType.const
        of "function": TokenType.function
        of "return":   TokenType.return
        of "if":       TokenType.if
        of "elif":     TokenType.elif
        of "else":     TokenType.else
        of "for":      TokenType.for
        of "while":    TokenType.while
        of "in":       TokenType.in
        of "is":       TokenType.is
        of "break":    TokenType.break
        of "continue": TokenType.continue
        of "using":    TokenType.using
        of "from":     TokenType.from
        of "watch":    TokenType.watch
        of "derive":   TokenType.derive
        of "true":     TokenType.bool
        of "false":    TokenType.bool
        of "and":      TokenType.and
        of "or":       TokenType.or
        of "not":      TokenType.not
        of "class":    TokenType.class
        of "try":      TokenType.try
        of "catch":    TokenType.catch
        of "finally":  TokenType.finally
        of "throw":    TokenType.throw
        of "match":    TokenType.match
        of "case":     TokenType.case
        else:          TokenType.ident

    if kind == TokenType.bool:
        return self.token(kind, toValue(ident == "true"))

    if kind == TokenType.ident:
        return self.token(kind, toValue(ident))

    return self.token(kind, noValue)

proc readToken(self: Lexer): Token =
    ## Get the token at the current position, consume it and return it.
    let char: Rune = self.peek()

    case char:
        of u"~":
            discard self.advance()
            if self.peek() == u">":
                discard self.advance()
                return self.token(TokenType.pipeline)
            else:
                return self.token(TokenType.concat)
        of u"+":
            discard self.advance()
            if self.peek() == u"=":
                discard self.advance()
                return self.token(TokenType.plusAssign)
            else:
                return self.token(TokenType.plus)
        of u"-":
            discard self.advance()
            if self.peek() == u"=":
                discard self.advance()
                return self.token(TokenType.minusAssign)
            elif self.peek() == u">":
                discard self.advance()
                return self.token(TokenType.arrow)
            else:
                return self.token(TokenType.minus)
        of u"*":
            discard self.advance()
            if self.peek() == u"=":
                discard self.advance()
                return self.token(TokenType.starAssign)
            else:
                return self.token(TokenType.star)
        of u"/":
            discard self.advance()
            if self.peek() == u"=":
                discard self.advance()
                return self.token(TokenType.slashAssign)
            else:
                return self.token(TokenType.slash)
        of Rune('"'), u"“":
            return self.readString()
        of Rune('`'):
            return self.readTemplate()
        else:
            if $char in "(){}[];:,.=<>!≈^%":
                # Single-character tokens
                var kind: TokenType = case char:
                    of u"(": TokenType.lParen
                    of u")": TokenType.rParen
                    of u"{": TokenType.lBrace
                    of u"}": TokenType.rBrace
                    of u"[": TokenType.lBracket
                    of u"]": TokenType.rBracket
                    of u";": TokenType.semicolon
                    of u":": TokenType.colon
                    of u",": TokenType.comma
                    of u"≈": TokenType.approx
                    of u"^": TokenType.caret
                    of u"%": TokenType.percent
                    else:    TokenType.eof

                # 2 character tokens
                if kind == TokenType.eof:
                    case self.advance():
                        of u"!":
                            if self.peek() == u"=":
                                kind = TokenType.neq
                                discard self.advance()
                            else:
                                raise self.error(StarchSyntaxError, "invalid syntax")
                        of u"=":
                            if self.peek() == u"=":
                                kind = TokenType.eq
                                discard self.advance()
                            elif self.peek() == u">":
                                kind = TokenType.fatArrow
                                discard self.advance()
                            else:
                                kind = TokenType.assign
                        of u">":
                            if self.peek() == u"=":
                                kind = TokenType.gte
                                discard self.advance()
                            else:
                                kind = TokenType.gt
                        of u"<":
                            if self.peek() == u"=":
                                kind = TokenType.lte
                                discard self.advance()
                            else:
                                kind = TokenType.lt
                        of u".":
                            if self.peek() == u".":
                                kind = TokenType.range
                                discard self.advance()
                            else:
                                kind = TokenType.dot
                        else:
                            discard # I have no idea why but there's NO HANDLING in the original Python code...
                else:
                    discard self.advance()

                return self.token(kind)

            elif int(char) in ord('0')..ord('9'):
                return self.readNumber()
            else:
                if char.isXIDStart() or char == u"_":
                    return self.readIdentOrKeyword()
                else:
                    raise self.error(StarchSyntaxError, &"unexpected character {$char}")

proc lex*(self: Lexer): seq[Token] =
    ## Scans the source code and returns a sequence of Tokens.
    while self.pos < self.code.len:
        self.startCol = self.col
        self.startPos = self.pos
        self.skipWhitespace()

        if self.pos >= self.code.len:
            break

        self.startCol = self.col
        self.startPos = self.pos
        self.tokens.add(self.readToken())

    self.tokens.add(Token(
        kind: TokenType.eof,
        value: noValue,
        line: self.line
    ))
    return self.tokens
