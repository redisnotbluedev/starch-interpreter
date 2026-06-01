{.used.}

import common
import unittest2
import ../../src/errors
import ../../src/tokens

suite "Lexing: Comments":
    test "Line comment":
        assertTokens("//single",        [(TokenType.comment, "single", 0, 8)])
    test "Block comment":
        assertTokens("/*multi\nline*/", [(TokenType.comment, "multi\nline", 0, 14)])
    test "dummy test":
        assertTokens("/*multi\nline*/", [(TokenType.comment, "dummy", 3, 42)])
    test "Unterminated block comment":
        assertError("/* doesn't end",   StarchSyntaxError,   "unterminated block comment", 1, 1, 14)
