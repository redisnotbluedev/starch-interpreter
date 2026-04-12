from enum import StrEnum
from dataclasses import dataclass
from errors import StarchError, StarchSyntaxError

class TokenType(StrEnum):
	# Literals
	NUMBER = "number"
	FLOAT = "float"
	STRING = "string"
	BOOL = "boolean"
	# Keywords
	VAR = "'var'"
	CONST = "'const'"
	FUNCTION = "'function'"
	RETURN = "'return'"
	IF = "'if'"
	ELIF = "'elif'"
	ELSE = "'else'"
	FOR = "'for'"
	WHILE = "'while'"
	IN = "'in'"
	IS = "'is'"
	BREAK = "'break'"
	CONTINUE = "'continue'"
	USING = "'using'"
	FROM = "'from'"
	WATCH = "'watch'"
	DERIVE = "'derive'"
	CLASS = "'class'"
	TRY = "'try'"
	CATCH = "'catch'"
	FINALLY = "'finally'"
	THROW = "'throw'"
	MATCH = "'match'"
	CASE = "'case'"
	# Identifiers
	IDENT = "identifier"
	# Operators
	PLUS = "'+'"
	MINUS = "'-'"
	STAR = "'*'"
	SLASH = "'/'"
	CARET = "'^'"
	PERCENT = "'%'"
	CONCAT = "'~'"
	PIPELINE = "'~>'"
	RANGE = "'..'"
	# Comparison
	EQ = "'=='"
	NEQ = "'!='"
	LT = "'<'"
	GT = "'>'"
	LTE = "'<='"
	GTE = "'>='"
	APPROX = "'≈'"
	# Logical
	AND = "'and'"
	OR = "'or'"
	NOT = "'not'"
	# Punctuation
	LPAREN = "'('"
	RPAREN = "')'"
	LBRACE = "'{'"
	RBRACE = "'}'"
	LBRACKET = "'['"
	RBRACKET = "']'"
	SEMICOLON = "';'"
	COLON = "':'"
	COMMA = "','"
	DOT = "'.'"
	ARROW = "'->'"
	FAT_ARROW = "'=>'"
	ASSIGN = "'='"
	# Compound assignment
	PLUS_ASSIGN = "'+='"
	MINUS_ASSIGN = "'-='"
	STAR_ASSIGN = "'*='"
	SLASH_ASSIGN = "'/='"
	# Special
	EOF = "end of file"

@dataclass
class Token:
	type: TokenType
	value: str | int | float | bool | None = None
	line: int = 0
	col: int = 0
	source_line: str = ""

	def __repr__(self):
		return f"Token(type='{self.type.name}', value={repr(self.value)})"

class Lexer:
	def __init__(self, code: str, file: str = "<starch-input>"):
		self.code = code
		self.pos = 0
		self.line = 1
		self.col = 1
		self.start_col = 1
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

	def token(self, type: str, value: str | int | float | bool | None = None):
		return Token(type, value, self.line, self.start_col, self.get_line())

	def lex(self) -> list[Token]:
		while self.pos < len(self.code):
			self.skip_whitespace()

			if self.pos >= len(self.code):
				break

			self.start_col = self.col
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
					self.tokens.append(self.token(TokenType.PIPELINE))
				else:
					self.tokens.append(self.token(TokenType.CONCAT))
			case "+":
				self.advance()
				if self.peek() == "=":
					self.advance()
					self.tokens.append(self.token(TokenType.PLUS_ASSIGN))
				else:
					self.tokens.append(self.token(TokenType.PLUS))
			case "-":
				self.advance()
				if self.peek() == "=":
					self.advance()
					self.tokens.append(self.token(TokenType.MINUS_ASSIGN))
				elif self.peek() == ">":
					self.advance()
					self.tokens.append(self.token(TokenType.ARROW))
				else:
					self.tokens.append(self.token(TokenType.MINUS))
			case "*":
				self.advance()
				if self.peek() == "=":
					self.advance()
					self.tokens.append(self.token(TokenType.STAR_ASSIGN))
				else:
					self.tokens.append(self.token(TokenType.STAR))
			case "/":
				self.advance()
				if self.peek() == "=":
					self.advance()
					self.tokens.append(self.token(TokenType.SLASH_ASSIGN))
				else:
					self.tokens.append(self.token(TokenType.SLASH))
			case '"':
				self.tokens.append(self.read_string())
			case _ if char in "(){}[];:,.=<>!≈^":
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
					"≈": TokenType.APPROX,
					"^": TokenType.CARET
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
							elif self.peek() == ">":
								type = TokenType.FAT_ARROW
								self.advance()
							else:
								type = TokenType.ASSIGN
						case ">":
							if self.peek() == "=":
								type = TokenType.GTE
								self.advance()
							else:
								type = TokenType.GT
						case "<":
							if self.peek() == "=":
								type = TokenType.LTE
								self.advance()
							else:
								type = TokenType.LT
						case ".":
							if self.peek() == ".":
								type = TokenType.RANGE
								self.advance()
							else:
								type = TokenType.DOT
				else:
					self.advance()

				self.tokens.append(self.token(type, None))

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

		return Token(TokenType.STRING, result, start_line, start_col, start_ctx)

	def read_number(self) -> Token:
		result = ""

		if self.peek() == "0" and self.peek(1).lower() in "xob":
			self.advance()
			prefix = self.advance()

			match prefix:
				case "x":
					while self.peek() and self.peek() in "0123456789abcdefABCDEF":
						result += self.advance()
					if not result:
						raise self.error(StarchSyntaxError, "invalid hexadecimal literal")
					return self.token(TokenType.NUMBER, int(result, 16))
				case "o":
					while self.peek() and self.peek() in "01234567":
						result += self.advance()
					if not result:
						raise self.error(StarchSyntaxError, "invalid octal literal")
					return self.token(TokenType.NUMBER, int(result, 8))
				case "b":
					while self.peek() and self.peek() in "01":
						result += self.advance()
					return self.token(TokenType.NUMBER, int(result, 2))
		elif self.peek(1).lower() == "e":
			result = self.advance()
			result += self.advance()

			if self.peek() in "+-":
				result += self.advance()
			while self.peek() and self.peek().isdigit():
				result += self.advance()
			return self.token(TokenType.FLOAT, float(result))

		while self.peek() and self.peek().isdigit():
			result += self.advance()

		if self.peek() == "." and self.peek(1).isdigit():
			result += self.advance()

			while self.peek() and self.peek().isdigit():
				result += self.advance()

			return self.token(TokenType.FLOAT, float(result))

		return self.token(TokenType.NUMBER, int(result))

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
			"is": TokenType.IS,
			"break": TokenType.BREAK,
			"continue": TokenType.CONTINUE,
			"using": TokenType.USING,
			"from": TokenType.FROM,
			"watch": TokenType.WATCH,
			"derive": TokenType.DERIVE,
			"true": TokenType.BOOL,
			"false": TokenType.BOOL,
			"and": TokenType.AND,
			"or": TokenType.OR,
			"not": TokenType.NOT,
			"class": TokenType.CLASS,
			"try": TokenType.TRY,
			"catch": TokenType.CATCH,
			"finally": TokenType.FINALLY,
			"throw": TokenType.THROW,
			"match": TokenType.MATCH,
			"case": TokenType.CASE
		}

		type = keywords.get(result, TokenType.IDENT)
		value = result if type == TokenType.IDENT else None
		if result in ("true", "false"):
			value = result == "true"

		return self.token(type, value)
