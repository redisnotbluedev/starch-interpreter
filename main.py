import sys
from lexer import Lexer
from errors import StarchError

def excepthook(type, value, traceback):
	if isinstance(value, StarchError):
		print(value, file=sys.stderr)
		sys.exit(1)
	else:
		sys.__excepthook__(type, value, traceback)

sys.excepthook = excepthook

if __name__ == "__main__":
	lexer = Lexer("var x: int = 1")
	tokens = lexer.lex()
	print(tokens)
