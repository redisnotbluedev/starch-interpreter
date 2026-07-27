"""Used to generate tests/lexer/static_tokens.nim.
Takes a section of the TokenType definition in Nim and extracts basic unit tests for every token listed."""

import re, pathlib

# Assumes simple_lexer_tests.py is in a tools/ directory (or similar) relative to the project root.
BASE_DIR = pathlib.Path(__file__).parent.parent

with open(BASE_DIR / "src" / "tokens.nim") as f:
	code = re.search("# === BEGIN SIMPLE TOKENS === #.*?# === END SIMPLE TOKENS === #", f.read(), re.DOTALL).group() # ty: ignore[unresolved-attribute]

# This regex extracts the key-value pairs from variable definitions regardless of whitespace:
# (key) = "(value)"
# Or just
# (key)
# Above, value is implicitly equal to key
matches = re.findall(r"""#[^\n]*|(?:(?<=^)|(?<=\s))(?:`?(\w+)`?\s*=\s*"([^"]+)"|`?(\w+)`?\b)""", code) # what a clean regex
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

with open(BASE_DIR / "tests" / "lexer" / "static_tokens.nim", "w") as f:
	f.write(text)
