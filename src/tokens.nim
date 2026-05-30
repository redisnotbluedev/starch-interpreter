type TokenType* = enum
    ## The type of a token.
    # Literals
    number, float, string, bool,
    # Definitions
    `var` = "'var'", `const` = "'const'", function = "'function'",
    `derive` = "'derive'", `class` = "'class'",
    # Branching
    `if` = "'if'", `elif` = "'elif'", `else` = "'else'",
    `match` = "'match'", `case` = "'case'",
    # Looping
    `for` = "'for'", `while` = "'while'",
    `break` = "'break'", `continue` = "'continue'",
    # Errors
    `try` = "'try'", `catch` = "'catch'", `finally` = "'finally'",
    `throw` = "'throw'",
    # Imports
    `using` = "'using'", `from` = "'from'",
    # Operators
    plus = "'+'", minus = "'-'", star = "'*'", slash = "'/'",
    caret = "'^'", percent = "'%'", concat = "'~'",
    pipeline = "'~>'", range = "'..'",
    # Comparison
    eq = "'=='", neq = "'!='", lt = "'<'", gt = "'>'", lte = "'<='",
    gte = "'>='", approx = "'≈'", `is` = "'is'", `in` = "'in'",
    # Logical
    `and` = "'and'", `or` = "'or'", `not` = "'not'",
    # Punctuation
    lParen = "'('", rParen = "')'", lBrace = "'{'",
    rBrace = "'}'", lBracket = "'['", rBracket = "']'",
    semicolon = "';'", colon = "':'", comma = "','", dot = "'.'",
    arrow = "'->'", fatArrow = "'=>'", assign = "'='",
    # Compound assignment
    plusAssign = "'+='", minusAssign = "'-='",
    starAssign = "'*='", slashAssign = "'/='",
    # Misc
    `return` = "'return'", ident = "identifier",
    watch = "'watch'", eof = "end of file"
