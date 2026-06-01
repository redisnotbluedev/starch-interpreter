import std/strformat
import std/enumutils

type TokenType* {.pure.} = enum
    ## The type of a token.
    # Literals
    number, float, string, bool,
    templateStart = "template string start",
    templateMiddle = "template string middle",
    templateEnd = "template string end",
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
    bang = "'!'", question = "'?'", pipe = "'|'",
    # Compound assignment
    plusAssign = "'+='", minusAssign = "'-='",
    starAssign = "'*='", slashAssign = "'/='",
    # Misc
    `return` = "'return'", watch = "'watch'",
    ident = "identifier",
    # Special
    comment = "comment", eof = "EOF"

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

proc `==`*(a, b: TokenValue): bool =
    ## Explicitly compare two TokenValue variants without using auto-generated reflection.
    if a.kind != b.kind: return false
    case a.kind:
    of ValueKind.string: return a.strVal == b.strVal
    of ValueKind.int:    return a.intVal == b.intVal
    of ValueKind.float:  return a.floatVal == b.floatVal
    of ValueKind.bool:   return a.boolVal == b.boolVal
    of ValueKind.none:   return true

# Shorthands for constructing values
const noValue* = TokenValue(kind: ValueKind.none)
converter toValue*(v: string): TokenValue          = TokenValue(kind: ValueKind.string, strVal: v)
converter toValue*(v: int): TokenValue             = TokenValue(kind: ValueKind.int, intVal: v)
converter toValue*(v: float): TokenValue           = TokenValue(kind: ValueKind.float, floatVal: v)
converter toValue*(v: bool): TokenValue            = TokenValue(kind: ValueKind.bool, boolVal: v)
converter toValue*(v: typeof(noValue)): TokenValue = v
