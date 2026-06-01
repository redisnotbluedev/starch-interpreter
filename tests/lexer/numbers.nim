{.used.}

import common
import unittest2
import ../../src/errors
import ../../src/tokens

suite "Lexing: Numbers":
    test "Integer":
        assertTokens("42",        [(TokenType.number, "42", 1, 1, 2)])
    test "Float":
        assertTokens("3.14159",   [(TokenType.float,  "3.14159", 1, 1, 7)])
    test "Seperators":
        assertTokens("1_000_000", [(TokenType.number, "1_000_000", 1, 1, 9)])
    test "Binary":
        assertTokens("0b1001001", [(TokenType.number, "0b1001001", 1, 1, 9)])
    test "Hex":
        assertTokens("0xC0ffEE",  [(TokenType.number, "0xC0ffEE", 1, 1, 8)])
    test "Octal":
        assertTokens("0o1337",    [(TokenType.number, "0o1337", 1, 1, 6)])
    test "Scientific notation":
        assertTokens("1e6",       [(TokenType.float,  "1e6", 1, 1, 3)])
    test "Scientific notation (signed)":
        assertTokens("1e-4",      [(TokenType.float,  "1e-4", 1, 1, 4)])
    test "Invalid binary":
        assertError("0b",         StarchSyntaxError,  "invalid binary literal", 1, 1, 2)
    test "Invalid hex":
        assertError("0x",         StarchSyntaxError,  "invalid hexadecimal literal", 1, 1, 2)
    test "Invalid octal":
        assertError("0o",         StarchSyntaxError,  "invalid octal literal", 1, 1, 2)
    test "Invalid scientific notation":
        assertError("5e",         StarchSyntaxError,  "invalid component in scientific notation literal", 1, 1, 2)
