{.used.}

import common
import unittest2
import ../../src/tokens

suite "Lexing: Keywords and symbols":
    test "'var' token":
        assertTokens("var",      [(TokenType.var,         noValue, 0, 3)])
    test "'const' token":
        assertTokens("const",    [(TokenType.const,       noValue, 0, 5)])
    test "'function' token":
        assertTokens("function", [(TokenType.function,    noValue, 0, 8)])
    test "'derive' token":
        assertTokens("derive",   [(TokenType.derive,      noValue, 0, 6)])
    test "'class' token":
        assertTokens("class",    [(TokenType.class,       noValue, 0, 5)])
    test "'if' token":
        assertTokens("if",       [(TokenType.if,          noValue, 0, 2)])
    test "'elif' token":
        assertTokens("elif",     [(TokenType.elif,        noValue, 0, 4)])
    test "'else' token":
        assertTokens("else",     [(TokenType.else,        noValue, 0, 4)])
    test "'match' token":
        assertTokens("match",    [(TokenType.match,       noValue, 0, 5)])
    test "'case' token":
        assertTokens("case",     [(TokenType.case,        noValue, 0, 4)])
    test "'for' token":
        assertTokens("for",      [(TokenType.for,         noValue, 0, 3)])
    test "'while' token":
        assertTokens("while",    [(TokenType.while,       noValue, 0, 5)])
    test "'break' token":
        assertTokens("break",    [(TokenType.break,       noValue, 0, 5)])
    test "'continue' token":
        assertTokens("continue", [(TokenType.continue,    noValue, 0, 8)])
    test "'try' token":
        assertTokens("try",      [(TokenType.try,         noValue, 0, 3)])
    test "'catch' token":
        assertTokens("catch",    [(TokenType.catch,       noValue, 0, 5)])
    test "'finally' token":
        assertTokens("finally",  [(TokenType.finally,     noValue, 0, 7)])
    test "'throw' token":
        assertTokens("throw",    [(TokenType.throw,       noValue, 0, 5)])
    test "'using' token":
        assertTokens("using",    [(TokenType.using,       noValue, 0, 5)])
    test "'from' token":
        assertTokens("from",     [(TokenType.from,        noValue, 0, 4)])
    test "'+' token":
        assertTokens("+",        [(TokenType.plus,        noValue, 0, 1)])
    test "'-' token":
        assertTokens("-",        [(TokenType.minus,       noValue, 0, 1)])
    test "'*' token":
        assertTokens("*",        [(TokenType.star,        noValue, 0, 1)])
    test "'/' token":
        assertTokens("/",        [(TokenType.slash,       noValue, 0, 1)])
    test "'++' token":
        assertTokens("++",       [(TokenType.plusPlus,    noValue, 0, 2)])
    test "'--' token":
        assertTokens("--",       [(TokenType.minusMinus,  noValue, 0, 2)])
    test "'^' token":
        assertTokens("^",        [(TokenType.caret,       noValue, 0, 1)])
    test "'%' token":
        assertTokens("%",        [(TokenType.percent,     noValue, 0, 1)])
    test "'~' token":
        assertTokens("~",        [(TokenType.concat,      noValue, 0, 1)])
    test "'~>' token":
        assertTokens("~>",       [(TokenType.pipeline,    noValue, 0, 2)])
    test "'..' token":
        assertTokens("..",       [(TokenType.range,       noValue, 0, 2)])
    test "'operator' token":
        assertTokens("operator", [(TokenType.operator,    noValue, 0, 8)])
    test "'==' token":
        assertTokens("==",       [(TokenType.eq,          noValue, 0, 2)])
    test "'!=' token":
        assertTokens("!=",       [(TokenType.neq,         noValue, 0, 2)])
    test "'<' token":
        assertTokens("<",        [(TokenType.lt,          noValue, 0, 1)])
    test "'>' token":
        assertTokens(">",        [(TokenType.gt,          noValue, 0, 1)])
    test "'<=' token":
        assertTokens("<=",       [(TokenType.lte,         noValue, 0, 2)])
    test "'>=' token":
        assertTokens(">=",       [(TokenType.gte,         noValue, 0, 2)])
    test "'≈' token":
        assertTokens("≈",        [(TokenType.approx,      noValue, 0, 1)])
    test "'is' token":
        assertTokens("is",       [(TokenType.is,          noValue, 0, 2)])
    test "'in' token":
        assertTokens("in",       [(TokenType.in,          noValue, 0, 2)])
    test "'and' token":
        assertTokens("and",      [(TokenType.and,         noValue, 0, 3)])
    test "'or' token":
        assertTokens("or",       [(TokenType.or,          noValue, 0, 2)])
    test "'not' token":
        assertTokens("not",      [(TokenType.not,         noValue, 0, 3)])
    test "'(' token":
        assertTokens("(",        [(TokenType.lParen,      noValue, 0, 1)])
    test "')' token":
        assertTokens(")",        [(TokenType.rParen,      noValue, 0, 1)])
    test "'{' token":
        assertTokens("{",        [(TokenType.lBrace,      noValue, 0, 1)])
    test "'}' token":
        assertTokens("}",        [(TokenType.rBrace,      noValue, 0, 1)])
    test "'[' token":
        assertTokens("[",        [(TokenType.lBracket,    noValue, 0, 1)])
    test "']' token":
        assertTokens("]",        [(TokenType.rBracket,    noValue, 0, 1)])
    test "';' token":
        assertTokens(";",        [(TokenType.semicolon,   noValue, 0, 1)])
    test "':' token":
        assertTokens(":",        [(TokenType.colon,       noValue, 0, 1)])
    test "',' token":
        assertTokens(",",        [(TokenType.comma,       noValue, 0, 1)])
    test "'.' token":
        assertTokens(".",        [(TokenType.dot,         noValue, 0, 1)])
    test "'->' token":
        assertTokens("->",       [(TokenType.arrow,       noValue, 0, 2)])
    test "'=>' token":
        assertTokens("=>",       [(TokenType.fatArrow,    noValue, 0, 2)])
    test "'=' token":
        assertTokens("=",        [(TokenType.assign,      noValue, 0, 1)])
    test "'!' token":
        assertTokens("!",        [(TokenType.bang,        noValue, 0, 1)])
    test "'?' token":
        assertTokens("?",        [(TokenType.question,    noValue, 0, 1)])
    test "'|' token":
        assertTokens("|",        [(TokenType.pipe,        noValue, 0, 1)])
    test "'+=' token":
        assertTokens("+=",       [(TokenType.plusAssign,  noValue, 0, 2)])
    test "'-=' token":
        assertTokens("-=",       [(TokenType.minusAssign, noValue, 0, 2)])
    test "'*=' token":
        assertTokens("*=",       [(TokenType.starAssign,  noValue, 0, 2)])
    test "'/=' token":
        assertTokens("/=",       [(TokenType.slashAssign, noValue, 0, 2)])
    test "'return' token":
        assertTokens("return",   [(TokenType.return,      noValue, 0, 6)])
    test "'watch' token":
        assertTokens("watch",    [(TokenType.watch,       noValue, 0, 5)])