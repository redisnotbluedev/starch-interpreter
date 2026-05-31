import std/strformat
import std/enumutils

type TokenType* {.pure.} = enum
    ## The type of a token.
    # Literals
    number, float, string, bool,
    templateStart = "template string",
    templateMiddle = "template string",
    templateEnd = "template string",
    # Definitions
    `var` = "'var'", `const` = "'const'", function = "'function'",
    `derive` = "'derive'", `class` = "'class'",
    # Branching
    `if` = "'if'", `elif` = "'elif'", `else` = "'else'",
    `match` = "'match'", `case` = "'case'",
    # Looping
    `for` = "'for'", `while` = "'while'",
    `break` = "'break'", `continue` = "'continue'",
    # Errors
    `try` = "'try'", `catch` = "'catch'", `finally` = "'finally'",
    `throw` = "'throw'",
    # Imports
    `using` = "'using'", `from` = "'from'",
    # Operators
    plus = "'+'", minus = "'-'", star = "'*'", slash = "'/'",
    caret = "'^'", percent = "'%'", concat = "'~'",
    pipeline = "'~>'", range = "'..'",
    # Comparison
    eq = "'=='", neq = "'!='", lt = "'<'", gt = "'>'", lte = "'<='",
    gte = "'>='", approx = "'≈'", `is` = "'is'", `in` = "'in'",
    # Logical
    `and` = "'and'", `or` = "'or'", `not` = "'not'",
    # Punctuation
    lParen = "'('", rParen = "')'", lBrace = "'{'",
    rBrace = "'}'", lBracket = "'['", rBracket = "']'",
    semicolon = "';'", colon = "':'", comma = "','", dot = "'.'",
    arrow = "'->'", fatArrow = "'=>'", assign = "'='",
    # Compound assignment
    plusAssign = "'+='", minusAssign = "'-='",
    starAssign = "'*='", slashAssign = "'/='",
    # Misc
    `return` = "'return'", ident = "identifier", watch = "'watch'"
    # Special
    comment = "comment", eof = "end of file"

type ValueKind* {.pure.} = enum none, string, int, float, bool
type TokenValue* = object
    ## The value of a token. Can be any ValueType.
    case kind*: ValueKind
    of ValueKind.string: strVal*: string
    of ValueKind.int:    intVal*: int
    of ValueKind.float:  floatVal*: float
    of ValueKind.bool:   boolVal*: bool
    of ValueKind.none:   discard
type Token* = object
    ## A single lexical unit produced by the lexer.
    ## Bundles a TokenType with positional data and a TokenValue.
    kind*: TokenType
    value*: TokenValue
    line*, col*, length*: int
proc `$`*(v: TokenValue): string =
    result = case v.kind:
        of ValueKind.string: &"'{v.strVal}'"
        of ValueKind.int:    $v.intVal
        of ValueKind.float:  $v.floatVal
        of ValueKind.bool:   $v.boolVal
        else: "none"
proc `$`*(t: Token): string =
    &"Token(type={symbolName(t.kind)}, value={t.value})"
