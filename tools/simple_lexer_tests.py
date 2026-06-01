"""Used to generate tests/lexer/static_tokens.nim.
Takes a section of the TokenType definition in Nim and extracts basic unit tests for every token listed."""

import re, pathlib

code = """
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
using = "'using'", `from` = "'from'",
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
bang = "'!'", question = "'?'", pipe = "'|'",
# Compound assignment
plusAssign = "'+='", minusAssign = "'-='",
starAssign = "'*='", slashAssign = "'/='",
# Misc
`return` = "'return'", watch = "'watch'",
"""
matches = re.findall(r"""#[^\n]*|\b(?:`?(\w+)`?\s*=\s*"([^"]+)"|`?(\w+)`?\b)""", code) # what a clean regex
tokens = []
text = """{.used.}\n\nimport common\nimport unittest2\nimport ../../src/tokens\n\nsuite "Lexing: Keywords and symbols":"""

for match in matches:
	if not any(match): continue
	if match[2]: # Standalone word with no value
		key = match[2]
		value = match[2]
	else:
		key, value = match[:2]

	pattern = value.strip("'")
	tokens.append((key, value, pattern))

longest_key = len(max(tokens, key=lambda t: len(t[0]))[0])
longest_value = len(max(tokens, key=lambda t: len(t[1]))[1])

for key, value, pattern in tokens:
	text += f"""\n    test "{value} token":\n        assertTokens("{pattern}", {" " * (longest_value - len(value))}[(TokenType.{key}, {" " * (longest_key - len(key))}noValue, 0, {len(pattern)})])"""

# Assumes simple_lexer_tests.py is in a tools/ directory (or similar) relative to the project root.
with open(pathlib.Path(__file__).parent.parent / "tests" / "lexer" / "static_tokens.nim", "w") as f:
	f.write(text)
