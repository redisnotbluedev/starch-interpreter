{.used.}

import common
import unittest2
import ../../src/errors
import ../../src/tokens

suite "Lexing: Template strings":
    test "Basic string":
        assertTokens("`hello world`",  [(TokenType.templateEnd,    "hello world", 0, 13)])
    test "Multiline":
        assertTokens("`hello\nworld`", [(TokenType.templateEnd,    "hello\nworld", 0, 13)])
    test "Interpolation":
        assertTokens("`hi ${name}`",   [(TokenType.templateStart,  "hi ", 0, 6),
                                        (TokenType.ident,          "name", 6, 4),
                                        (TokenType.templateEnd,    "", 10, 2)])
    test "Multiple interpolations":
        assertTokens("`h${e}l${l}o`",  [(TokenType.templateStart,  "h", 0, 4),
                                        (TokenType.ident,          "e", 4, 1),
                                        (TokenType.templateMiddle, "l", 5, 4),
                                        (TokenType.ident,          "l", 9, 1),
                                        (TokenType.templateEnd,    "o", 10, 3)])
    test "Unterminated string":
        assertError("`hello",          StarchSyntaxError, "unterminated template literal", 1, 1, 6)
    test "Unterminated interpolation expression":
        assertError("`hello ${world",  StarchSyntaxError, "EOF while scanning template interpolation", 1, 10, 5)
