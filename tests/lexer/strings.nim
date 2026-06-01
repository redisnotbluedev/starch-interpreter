{.used.}

import common
import unittest2
import ../../src/errors
import ../../src/tokens

suite "Lexing: Strings":
    test "Basic string":
        assertTokens(""""hello world"""",  [(TokenType.string, "hello world", 1, 1, 13)])
    test "Smart quotes":
        assertTokens("“hello world”",      [(TokenType.string, "hello world", 1, 1, 13)])
    test "Escaped newline":
        assertTokens(""""hello\nworld"""", [(TokenType.string, "hello\nworld", 1, 1, 14)])
    test "Escaped tab":
        assertTokens(""""hello\tworld"""", [(TokenType.string, "hello\tworld", 1, 1, 14)])
    test "Escaped backslash":
        assertTokens(""""hello\\world"""", [(TokenType.string, "hello\\world", 1, 1, 14)])
    test "Invalid escape sequence":
        assertError(""""hello\bworld"""",  StarchSyntaxError, "invalid escape sequence '\\b'", 1, 7, 2)
    test "Unterminated string":
        assertError(""""hello world""",    StarchSyntaxError, "unterminated string literal", 1, 1, 12)
    test "Unterminated string (with smart quote)":
        assertError("""“hello world""",    StarchSyntaxError, "unterminated string literal. Perhaps you tried to close with a straight" &
                                                              " quote ('\"') instead of a smart quote ('”')?", 1, 1, 12)
