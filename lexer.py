from dataclasses import dataclass
from errors import StarchError, StarchSyntaxError

class TokenType:
	# Literals
	NUMBER = "NUMBER"
	FLOAT = "FLOAT"
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
	def __init__(self, code: str, file: str = "<starch-input>"):
		self.code = code
		self.pos = 0
		self.line = 1
		self.col = 1
		self.tokens = []
		self.file = file

	def peek(self, offset=0) -> str | None:
		i = self.pos + offset
		return self.code[i] if i < len(self.code) else None

	def advance(self) -> str:
		char = self.code[self.pos]
		self.pos += 1
		if char == "\n":
			self.line += 1
			self.col = 1
		else:
			self.col += 1
		return char

	def get_line(self) -> str:
		lines = self.code.splitlines()
		if self.line <= len(lines):
			return lines[self.line - 1]  # line is 1-indexed
		return ""

	def error(self, type: type[StarchError], message: str):
		return type(message, self.line, self.get_line(), self.col, self.file)

	def lex(self) -> list[Token]:
		while self.pos < len(self.code):
			self.skip_whitespace()
			if self.pos >= len(self.code):
				break

			self.read_token()

		self.tokens.append(Token(TokenType.EOF, line=self.line))
		return self.tokens

	def skip_whitespace(self):
		while self.peek():
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
					else:
						raise self.error(StarchSyntaxError, "unterminated block comment")
				else:
					break
			else:
				break

	def read_token(self):
		char = self.peek()
		assert char is not None

		match char:
			case "~":
				self.advance()
				if self.peek() == ">":
					self.advance()
					self.tokens.append(Token(TokenType.PIPELINE, line=self.line))
				else:
					self.tokens.append(Token(TokenType.CONCAT, line=self.line))
			case "+":
				self.advance()
				if self.peek() == "=":
					self.advance()
					self.tokens.append(Token(TokenType.PLUS_ASSIGN, line=self.line))
				else:
					self.tokens.append(Token(TokenType.PLUS, line=self.line))
			case "-":
				self.advance()
				if self.peek() == "=":
					self.advance()
					self.tokens.append(Token(TokenType.MINUS_ASSIGN, line=self.line))
				else:
					self.tokens.append(Token(TokenType.MINUS, line=self.line))
			case "*":
				self.advance()
				if self.peek() == "=":
					self.advance()
					self.tokens.append(Token(TokenType.STAR_ASSIGN, line=self.line))
				else:
					self.tokens.append(Token(TokenType.STAR, line=self.line))
			case "/":
				self.advance()
				if self.peek() == "=":
					self.advance()
					self.tokens.append(Token(TokenType.SLASH_ASSIGN, line=self.line))
				else:
					self.tokens.append(Token(TokenType.SLASH, line=self.line))
			case '"':
				self.tokens.append(self.read_string())
			case _ if char in "(){}[];:,.=<>!≈":
				type = {
					"(": TokenType.LPAREN,
					")": TokenType.RPAREN,
					"{": TokenType.LBRACE,
					"}": TokenType.RBRACE,
					"[": TokenType.LBRACKET,
					"]": TokenType.RBRACKET,
					";": TokenType.SEMICOLON,
					":": TokenType.COLON,
					",": TokenType.COMMA,
					".": TokenType.DOT,
					"≈": TokenType.APPROX
				}.get(char)

				if type is None:
					match self.advance():
						case "!":
							if self.peek() == "=":
								type = TokenType.NEQ
								self.advance()
							else:
								raise self.error(StarchSyntaxError, "invalid syntax")
						case "=":
							if self.peek() == "=":
								type = TokenType.EQ
								self.advance()
							else:
								type = TokenType.ASSIGN
						case "<":
							if self.peek() == "=":
								type = TokenType.GTE
								self.advance()
							else:
								type = TokenType.GT
						case ">":
							if self.peek() == "=":
								type = TokenType.LTE
								self.advance()
							else:
								type = TokenType.LT
				else:
					self.advance()

				self.tokens.append(Token(type, None, self.line))

			case _ if char.isdigit():
				self.tokens.append(self.read_number())
			case _ if char.isalpha() or char == "_":
				self.tokens.append(self.read_ident_or_keyword())
			case _:
				raise self.error(StarchSyntaxError, f"unexpected character '{char}'")

	def read_string(self) -> Token:
		start_line = self.line
		start_col = self.col
		start_ctx = self.get_line()

		self.advance()
		result = ""

		while self.peek():
			if self.peek() == "\\":
				self.advance()
				match self.peek():
					case "n":
						self.advance()
						result += "\n"
					case "t":
						self.advance()
						result += "\t"
					case "\\":
						self.advance()
						result += "\\"
					case '"':
						self.advance()
						result += '"'
					case _:
						raise self.error(StarchSyntaxError, f"invalid escape sequence '\\{self.peek()}'")
			elif self.peek() == '"':
				self.advance()
				break
			else:
				result += self.advance()
		else:
			raise StarchSyntaxError("unterminated string literal", start_line, start_ctx, start_col, self.file)

		return Token(TokenType.STRING, result, self.line)

	def read_number(self) -> Token:
		result = ""

		if self.peek() == "0" and self.peek(1).lower() in "xob":
			self.advance()
			prefix = self.advance()

			match prefix:
				case "x":
					while self.peek() and self.peek() in "0123456789abcdefABCDEF":
						result += self.advance()
					return Token(TokenType.NUMBER, int(result, 16), self.line)
				case "o":
					while self.peek() and self.peek() in "01234567":
						result += self.advance()
					return Token(TokenType.NUMBER, int(result, 8), self.line)
				case "b":
					while self.peek() and self.peek() in "01":
						result += self.advance()
					return Token(TokenType.NUMBER, int(result, 2), self.line)
		elif self.peek(1).lower() == "e":
			result = self.advance()
			result += self.advance()

			if self.peek() in "+-":
				result += self.advance()
			while self.peek() and self.peek().isdigit():
				result += self.advance()
			return Token(TokenType.FLOAT, float(result), self.line)

		while self.peek() and self.peek().isdigit():
			result += self.advance()

		if self.peek() == "." and self.peek(1):
			result += self.advance()

			while self.peek() and self.peek().isdigit():
				result += self.advance()

			return Token(TokenType.FLOAT, float(result), self.line)

		return Token(TokenType.NUMBER, int(result), self.line)

	def read_ident_or_keyword(self) -> Token:
		result = ""
		while self.peek() and (self.peek().isalnum() or self.peek() == "_"):
			result += self.advance()

		keywords = {
			"var": TokenType.VAR,
			"const": TokenType.CONST,
			"function": TokenType.FUNCTION,
			"return": TokenType.RETURN,
			"if": TokenType.IF,
			"elif": TokenType.ELIF,
			"else": TokenType.ELSE,
			"for": TokenType.FOR,
			"while": TokenType.WHILE,
			"in": TokenType.IN,
			"using": TokenType.USING,
			"watch": TokenType.WATCH,
			"derive": TokenType.DERIVE,
			"true": TokenType.BOOL,
			"false": TokenType.BOOL,
			"and": TokenType.AND,
			"or": TokenType.OR,
			"not": TokenType.NOT,
			"class": TokenType.CLASS,
			"this": TokenType.THIS,
			"super": TokenType.SUPER,
		}

		type = keywords.get(result, TokenType.IDENT)
		value = result if type == TokenType.IDENT else None
		if result in ("true", "false"):
			value = result == "true"

		return Token(type, value, self.line)
