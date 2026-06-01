{.used.}

import common
import unittest2
import ../../src/errors
import ../../src/tokens

suite "Lexing: Template strings":
    test "Basic string":
        assertTokens("`hello world`",  [(TokenType.templateEnd,    "hello world", 1, 1, 13)])
    test "Multiline":
        assertTokens("`hello\nworld`", [(TokenType.templateEnd,    "hello\nworld", 1, 1, 13)])
    test "Interpolation":
        assertTokens("`hi ${name}`",   [(TokenType.templateStart,  "hi ", 1, 1, 6),
                                        (TokenType.ident,          "name", 1, 7, 4),
                                        (TokenType.templateEnd,    "", 1, 1, 12)])
    test "Multiple interpolations":
        assertTokens("`h${e}l${l}o`",  [(TokenType.templateStart,  "h", 1, 1, 4),
                                        (TokenType.ident,          "e", 1, 5, 1),
                                        (TokenType.templateMiddle, "l", 1, 1, 5),
                                        (TokenType.ident,          "l", 1, 10, 1),
                                        (TokenType.templateEnd,    "o", 1, 1, 13)])
    test "Unterminated string":
        assertError("`hello",          StarchSyntaxError, "unterminated template literal", 1, 1, 1)
    test "Unterminated interpolation expression":
        assertError("`hello ${world",  StarchSyntaxError, "EOF while scanning template interpolation", 1, 10, 1)
