{.used.}

import common
import unittest2
import ../../src/tokens

suite "Lexing: Keywords and symbols":
    test "'var' token":
        assertTokens("var",      [(TokenType.var,         noValue, 1, 1, 3)])
    test "'const' token":
        assertTokens("const",    [(TokenType.const,       noValue, 1, 1, 5)])
    test "'function' token":
        assertTokens("function", [(TokenType.function,    noValue, 1, 1, 8)])
    test "'derive' token":
        assertTokens("derive",   [(TokenType.derive,      noValue, 1, 1, 6)])
    test "'class' token":
        assertTokens("class",    [(TokenType.class,       noValue, 1, 1, 5)])
    test "'if' token":
        assertTokens("if",       [(TokenType.if,          noValue, 1, 1, 2)])
    test "'elif' token":
        assertTokens("elif",     [(TokenType.elif,        noValue, 1, 1, 4)])
    test "'else' token":
        assertTokens("else",     [(TokenType.else,        noValue, 1, 1, 4)])
    test "'match' token":
        assertTokens("match",    [(TokenType.match,       noValue, 1, 1, 5)])
    test "'case' token":
        assertTokens("case",     [(TokenType.case,        noValue, 1, 1, 4)])
    test "'for' token":
        assertTokens("for",      [(TokenType.for,         noValue, 1, 1, 3)])
    test "'while' token":
        assertTokens("while",    [(TokenType.while,       noValue, 1, 1, 5)])
    test "'break' token":
        assertTokens("break",    [(TokenType.break,       noValue, 1, 1, 5)])
    test "'continue' token":
        assertTokens("continue", [(TokenType.continue,    noValue, 1, 1, 8)])
    test "'try' token":
        assertTokens("try",      [(TokenType.try,         noValue, 1, 1, 3)])
    test "'catch' token":
        assertTokens("catch",    [(TokenType.catch,       noValue, 1, 1, 5)])
    test "'finally' token":
        assertTokens("finally",  [(TokenType.finally,     noValue, 1, 1, 7)])
    test "'throw' token":
        assertTokens("throw",    [(TokenType.throw,       noValue, 1, 1, 5)])
    test "'using' token":
        assertTokens("using",    [(TokenType.using,       noValue, 1, 1, 5)])
    test "'from' token":
        assertTokens("from",     [(TokenType.from,        noValue, 1, 1, 4)])
    test "'+' token":
        assertTokens("+",        [(TokenType.plus,        noValue, 1, 1, 1)])
    test "'-' token":
        assertTokens("-",        [(TokenType.minus,       noValue, 1, 1, 1)])
    test "'*' token":
        assertTokens("*",        [(TokenType.star,        noValue, 1, 1, 1)])
    test "'/' token":
        assertTokens("/",        [(TokenType.slash,       noValue, 1, 1, 1)])
    test "'^' token":
        assertTokens("^",        [(TokenType.caret,       noValue, 1, 1, 1)])
    test "'%' token":
        assertTokens("%",        [(TokenType.percent,     noValue, 1, 1, 1)])
    test "'~' token":
        assertTokens("~",        [(TokenType.concat,      noValue, 1, 1, 1)])
    test "'~>' token":
        assertTokens("~>",       [(TokenType.pipeline,    noValue, 1, 1, 2)])
    test "'..' token":
        assertTokens("..",       [(TokenType.range,       noValue, 1, 1, 2)])
    test "'==' token":
        assertTokens("==",       [(TokenType.eq,          noValue, 1, 1, 2)])
    test "'!=' token":
        assertTokens("!=",       [(TokenType.neq,         noValue, 1, 1, 2)])
    test "'<' token":
        assertTokens("<",        [(TokenType.lt,          noValue, 1, 1, 1)])
    test "'>' token":
        assertTokens(">",        [(TokenType.gt,          noValue, 1, 1, 1)])
    test "'<=' token":
        assertTokens("<=",       [(TokenType.lte,         noValue, 1, 1, 2)])
    test "'>=' token":
        assertTokens(">=",       [(TokenType.gte,         noValue, 1, 1, 2)])
    test "'≈' token":
        assertTokens("≈",        [(TokenType.approx,      noValue, 1, 1, 1)])
    test "'is' token":
        assertTokens("is",       [(TokenType.is,          noValue, 1, 1, 2)])
    test "'in' token":
        assertTokens("in",       [(TokenType.in,          noValue, 1, 1, 2)])
    test "'and' token":
        assertTokens("and",      [(TokenType.and,         noValue, 1, 1, 3)])
    test "'or' token":
        assertTokens("or",       [(TokenType.or,          noValue, 1, 1, 2)])
    test "'not' token":
        assertTokens("not",      [(TokenType.not,         noValue, 1, 1, 3)])
    test "'(' token":
        assertTokens("(",        [(TokenType.lParen,      noValue, 1, 1, 1)])
    test "')' token":
        assertTokens(")",        [(TokenType.rParen,      noValue, 1, 1, 1)])
    test "'{' token":
        assertTokens("{",        [(TokenType.lBrace,      noValue, 1, 1, 1)])
    test "'}' token":
        assertTokens("}",        [(TokenType.rBrace,      noValue, 1, 1, 1)])
    test "'[' token":
        assertTokens("[",        [(TokenType.lBracket,    noValue, 1, 1, 1)])
    test "']' token":
        assertTokens("]",        [(TokenType.rBracket,    noValue, 1, 1, 1)])
    test "';' token":
        assertTokens(";",        [(TokenType.semicolon,   noValue, 1, 1, 1)])
    test "':' token":
        assertTokens(":",        [(TokenType.colon,       noValue, 1, 1, 1)])
    test "',' token":
        assertTokens(",",        [(TokenType.comma,       noValue, 1, 1, 1)])
    test "'.' token":
        assertTokens(".",        [(TokenType.dot,         noValue, 1, 1, 1)])
    test "'->' token":
        assertTokens("->",       [(TokenType.arrow,       noValue, 1, 1, 2)])
    test "'=>' token":
        assertTokens("=>",       [(TokenType.fatArrow,    noValue, 1, 1, 2)])
    test "'=' token":
        assertTokens("=",        [(TokenType.assign,      noValue, 1, 1, 1)])
    test "'!' token":
        assertTokens("!",        [(TokenType.bang,        noValue, 1, 1, 1)])
    test "'?' token":
        assertTokens("?",        [(TokenType.question,    noValue, 1, 1, 1)])
    test "'|' token":
        assertTokens("|",        [(TokenType.pipe,        noValue, 1, 1, 1)])
    test "'+=' token":
        assertTokens("+=",       [(TokenType.plusAssign,  noValue, 1, 1, 2)])
    test "'-=' token":
        assertTokens("-=",       [(TokenType.minusAssign, noValue, 1, 1, 2)])
    test "'*=' token":
        assertTokens("*=",       [(TokenType.starAssign,  noValue, 1, 1, 2)])
    test "'/=' token":
        assertTokens("/=",       [(TokenType.slashAssign, noValue, 1, 1, 2)])
    test "'return' token":
        assertTokens("return",   [(TokenType.return,      noValue, 1, 1, 6)])
    test "'watch' token":
        assertTokens("watch",    [(TokenType.watch,       noValue, 1, 1, 5)])