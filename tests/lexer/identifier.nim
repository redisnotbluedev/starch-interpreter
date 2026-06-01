{.used.}

import common
import unittest2
import ../../src/errors
import ../../src/tokens

suite "Lexing: Identifiers":
    test "ASCII identifier":
        assertTokens("hello",   [(TokenType.ident,  "hello", 1, 1, 5)])
    test "Starts with underscore":
        assertTokens("_hidden", [(TokenType.ident,  "_hidden", 1, 1, 7)])
    test "Unicode":
        assertTokens("你好",     [(TokenType.ident,  "你好", 1, 1, 2)])
    test "XID_Nonstart":
        assertError("٢_items",   StarchSyntaxError, "unexpected character '٢'", 1, 1, 1)
