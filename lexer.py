from dataclasses import dataclass

class TokenType:
	# Literals
	NUMBER = "NUMBER"
	STRING = "STRING"
	BOOL = "BOOL"
	# Keywords
	VAR = "VAR"
	CONST = "CONST"
	FUNCTION = "FUNCTION"
	RETURN = "RETURN"
	IF = "IF"
	ELIF = "ELIF"
	ELSE = "ELSE"
	FOR = "FOR"
	WHILE = "WHILE"
	IN = "IN"
	USING = "USING"
	WATCH = "WATCH"
	DERIVE = "DERIVE"
	CLASS = "CLASS"
	THIS = "THIS"
	SUPER = "SUPER"
	# Identifiers
	IDENT = "IDENT"
	# Operators
	PLUS = "PLUS"
	MINUS = "MINUS"
	STAR = "STAR"
	SLASH = "SLASH"
	CARET = "CARET"
	PERCENT = "PERCENT"
	CONCAT = "CONCAT"
	PIPELINE = "PIPELINE"
	RANGE = "RANGE"
	# Comparison
	EQ = "EQ"
	NEQ = "NEQ"
	LT = "LT"
	GT = "GT"
	LTE = "LTE"
	GTE = "GTE"
	APPROX = "APPROX"
	# Logical
	AND = "AND"
	OR = "OR"
	NOT = "NOT"
	# Punctuation
	LPAREN = "LPAREN"
	RPAREN = "RPAREN"
	LBRACE = "LBRACE"
	RBRACE = "RBRACE"
	LBRACKET = "LBRACKET"
	RBRACKET = "RBRACKET"
	SEMICOLON = "SEMICOLON"
	COLON = "COLON"
	COMMA = "COMMA"
	DOT = "DOT"
	ARROW = "ARROW"
	ASSIGN = "ASSIGN"
	# Compound assignment
	PLUS_ASSIGN = "PLUS_ASSIGN"
	MINUS_ASSIGN = "MINUS_ASSIGN"
	STAR_ASSIGN = "STAR_ASSIGN"
	SLASH_ASSIGN = "SLASH_ASSIGN"
	# Types
	TYPE_INT = "TYPE_INT"
	TYPE_FLOAT = "TYPE_FLOAT"
	TYPE_STR = "TYPE_STR"
	TYPE_BOOL = "TYPE_BOOL"
	TYPE_LIST = "TYPE_LIST"
	TYPE_DICT = "TYPE_DICT"
	TYPE_VOID = "TYPE_VOID"
	# Special
	EOF = "EOF"

@dataclass
class Token:
	type: str
	value: str | int | float | bool | None = None
	line: int = 0

class Lexer:
	def __init__(self, code: str):
		self.code = code
		self.pos = 0
		self.line = 1
		self.tokens = []

	def peek(self, offset=0) -> str | None:
		i = self.pos + offset
		return self.code[i] if i < len(self.code) else None

	def advance(self) -> str:
		char = self.code[self.pos]
		self.pos += 1
		if char == "\n":
			self.line += 1
		return char

	def lex(self) -> list[Token]:
		while self.pos < len(self.code):
			self.skip_whitespace()
			if self.pos >= len(self.code):
				break

		self.tokens.append(Token(TokenType.EOF))
		return self.tokens

	def skip_whitespace(self):
		if (self.peek() or "") in " \n\t\r":
			self.advance()
		elif self.peek() == "/":
			if self.peek(1) == "/":
				while self.peek() and self.peek() != "\n":
					self.advance()
			elif self.peek(1) == "*":
				self.advance()
				self.advance()

				while self.peek():
					if self.peek() == "*" and self.peek(1) == "/":
						self.advance()
						self.advance()
						break
					self.advance()
		elif self.peek() == "#":
			while self.peek() and self.peek() != "\n":
				self.advance()
