from lexer import Lexer

if __name__ == "__main__":
	lexer = Lexer("var x: int = 1")
	tokens = lexer.lex()
	print(tokens)
