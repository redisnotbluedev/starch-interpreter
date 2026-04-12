import sys
from lexer import Lexer
from parser import Parser
from errors import StarchError

def excepthook(type, value, traceback):
	if isinstance(value, StarchError):
		print(value, file=sys.stderr)
		sys.exit(1)
	else:
		sys.__excepthook__(type, value, traceback)

sys.excepthook = excepthook

if __name__ == "__main__":
	with open("main.starch") as f:
		lexer = Lexer(f.read(), "main.starch")
		tokens = lexer.lex()
		print(tokens)

		print()

		parser = Parser(tokens, "main.starch")
		tree = parser.parse()
		print(tree)
