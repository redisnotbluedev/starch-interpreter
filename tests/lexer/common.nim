import std/macros
import unittest2
import ../../src/errors
import ../../src/lexer
import ../../src/tokens

# Why is all this necessary?
# Well you see, Nim really, REALLY, REALLY doesn't like sequences with different types
# Like this:
#     @[(TokenType, string), (TokenType, bool)]
# Which is exactly what we're doing here
# So, a bunch of converter black magic
macro tokenSeq*(args: untyped): seq[(TokenType, TokenValue, int, int, int)] =
    ## Intercepts the array syntax and applies `toValue` to every 2nd value.
    result = newNimNode(nnkPrefix)
    result.add ident("@") # Build a seq literal

    let arrayNode = newNimNode(nnkBracket)

    # Unwrap bracket if passed as a literal array e.g. [(kind, val)]
    let list = if args.kind == nnkBracket: args else: args[0]

    for pair in list:
        pair.expectKind(nnkTupleConstr)
        let kindExpr = pair[0]
        let valExpr = pair[1]

        # Construct: (kindExpr, toValue(valExpr), line, col, length)
        let mappedTuple = newNimNode(nnkTupleConstr).add(
            kindExpr,
            newCall(ident("toValue"), valExpr),
            pair[2],
            pair[3],
            pair[4]
        )
        arrayNode.add(mappedTuple)

    result.add(arrayNode)
converter toTokenTuple*[T](pair: (TokenType, T)): (TokenType, TokenValue) = (pair[0], toValue(pair[1]))
converter toNoneTuple*(pair: (TokenType, typeof(noValue))): (TokenType, TokenValue) = (pair[0], pair[1])
proc assertTokensImpl(source: string, expected: seq[(TokenType, TokenValue, int, int, int)]) =
    var tokens = newLexer(source, "<test input>").lex()
    check(tokens.len == expected.len + 1)
    for i, exp in expected:
        if i < tokens.len:
            let (kind, value, line, col, length) = exp
            check(tokens[i].kind == kind)
            check(tokens[i].value == value)
            check(tokens[i].line == line)
            check(tokens[i].col == col)
            check(tokens[i].length == length)
template assertTokens*(source: string, expected: untyped) = assertTokensImpl(source, tokenSeq(expected))

proc assertError*(source: string, kind: typedesc[StarchError], message: string, line: int, col: int, length: int) =
    ## Helper to quickly verify that a source string raises the given error with message.
    try:
        discard newLexer(source, "<test input>").lex()
        checkpoint("Expected " & $kind & " to be raised, but code ran successfully without errors.")
        fail()
    except StarchError as e:
        check(e of kind)
        check(e.originalMessage == message)
        check(e.line == line)
        check(e.col == col)
        check(e.length == length)
