{.used.}

import common
import unittest2
import ../../src/tokens

suite "Lexing: Booleans":
    test "True":
        assertTokens("true",  [(TokenType.bool, true, 1, 1, 4)])
    test "False":
        assertTokens("false", [(TokenType.bool, false, 1, 1, 5)])
