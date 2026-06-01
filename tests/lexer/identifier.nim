{.used.}

import common
import unittest2
import ../../src/errors
import ../../src/tokens

suite "Lexing: Identifiers":
    test "ASCII identifier":
        assertTokens("hello",   [(TokenType.ident,  "hello", 0, 5)])
    test "Starts with underscore":
        assertTokens("_hidden", [(TokenType.ident,  "_hidden", 0, 7)])
    test "Unicode":
        assertTokens("你好",     [(TokenType.ident,  "你好", 0, 2)])
    test "XID_Nonstart":
        assertError("٢_items",   StarchSyntaxError, "unexpected character '٢'", 1, 1, 1)
    test "With number":
        assertTokens("day99",    [(TokenType.ident,  "day99", 0, 5)])
    test "With keyword":
        assertTokens("if_value", [(TokenType.ident,  "if_value", 0, 8)])
