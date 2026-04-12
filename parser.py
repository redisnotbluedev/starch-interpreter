from dataclasses import dataclass
from lexer import Token, TokenType
from errors import StarchError, StarchSyntaxError

@dataclass
class Program:
	statements: list

@dataclass
class Node():
	line: int
	col: int
	source_line: str

	def __repr__(self) -> str:
		fields = {
			k: v for k, v in self.__dict__.items()
			if k not in ("line", "col", "source_line")
		}
		inner = ", ".join(f"{k}={v!r}" for k, v in fields.items())
		return f"{self.__class__.__name__}({inner})"

@dataclass(repr=False)
class VarDeclaration(Node):
	name: str
	type: str | None
	value: Node
	mutable: bool

@dataclass(repr=False)
class Literal(Node):
	value: int | float | str | bool

@dataclass(repr=False)
class Identifier(Node):
	name: str

@dataclass(repr=False)
class FunctionCall(Node):
	callee: Node
	args: list[Node]

@dataclass(repr=False)
class MemberAccess(Node):
	callee: Node
	member: Identifier

@dataclass(repr=False)
class ExpressionStatement(Node):
	expression: Node

@dataclass(repr=False)
class UnaryOp(Node):
	operator: str
	operand: Node

@dataclass(repr=False)
class BinaryOp(Node):
	operator: str
	left: Node
	right: Node

def node(token: Token, type: type[Node], *args, **kwargs):
	return type(token.line, token.col, token.source_line, *args, **kwargs)

class Parser:
	def __init__(self, tokens: list[Token], file: str):
		self.tokens = tokens
		self.file = file
		self.pos = 0

	def error(self, type: type[StarchError], message: str):
		token = self.current
		return type(message, token.line, token.source_line, token.col, self.file)

	@property
	def current(self) -> Token:
		return self.tokens[self.pos]

	def peek(self, offset: int = 1) -> Token:
		pos = self.pos + offset
		if pos >= len(self.tokens):
			return self.tokens[-1]  # EOF
		return self.tokens[pos]

	def advance(self) -> Token:
		token = self.current
		self.pos += 1
		return token

	def expect(self, type: TokenType) -> Token:
		if self.current.type != type:
			raise self.error(StarchSyntaxError, f"Expected {type}, got {self.current.type}")
		return self.advance()

	def terminate(self):
		last = self.peek(-1)
		if self.current.type != TokenType.SEMICOLON:
			if self.current.line != last.line:
				raise StarchSyntaxError(f"Expected {TokenType.SEMICOLON}", last.line, last.source_line, len(last.source_line) + 1, self.file)
			else:
				raise self.error(StarchSyntaxError, f"Expected {TokenType.SEMICOLON}, got {self.current.type}")

		self.advance()

	def match(self, *types: TokenType) -> bool:
		if self.current.type in types:
			self.advance()
			return True
		return False

	def parse(self) -> Program:
		statements = []

		while self.current.type != TokenType.EOF:
			statements.append(self.parse_statement())

		return Program(statements)

	def parse_statement(self) -> Node:
		match self.current.type:
			case TokenType.VAR | TokenType.CONST:
				return self.parse_var_decl()
			case _:
				return self.parse_expression_statement()

	def parse_var_decl(self) -> Node:
		token = self.advance()

		name = self.expect(TokenType.IDENT).value
		type = None

		if self.current.type == TokenType.COLON:
			self.advance()
			type = self.expect(TokenType.IDENT).value

		self.expect(TokenType.ASSIGN)
		value = self.parse_expression()

		self.terminate()

		return node(token, VarDeclaration, name, type, value, token.type == TokenType.VAR)

	def parse_expression_statement(self) -> Node:
		token = self.current
		expression = self.parse_expression()
		self.terminate()
		return node(token, ExpressionStatement, expression)

	"""
	parse_expression        # entry point
    parse_pipeline      # ~>  (lowest precedence)
        parse_or        # or
            parse_and   # and
                parse_not       # not (unary)
                    parse_comparison    # == != < > <= >= ≈
                        parse_concat    # ~
                            parse_range     # ..
                                parse_additive      # + -
                                    parse_multiplicative    # * / %
                                        parse_exponent      # ^
                                            parse_unary     # - (negative)
                                                parse_call      # func() obj.member
                                                    parse_primary   # literals, identifiers, (expr)
	"""

	def parse_expression(self) -> Node:
		return self.parse_exponent()

	def parse_exponent(self) -> Node:
		base = self.parse_unary()
		if self.current.type == TokenType.CARET:
			token = self.current
			self.advance()
			return node(token, BinaryOp, "^", base, self.parse_exponent())
		return base

	def parse_unary(self) -> Node:
		token = self.current
		if token.type == TokenType.MINUS:
			self.advance()
			return node(token, UnaryOp, "-", self.parse_unary())

		return self.parse_call()

	def parse_call(self) -> Node:
		expression = self.parse_primary()

		while True:
			token = self.current

			match token.type:
				case TokenType.LPAREN:
					self.advance()
					args = []
					while self.current.type != TokenType.RPAREN:
						args.append(self.parse_expression())
						if self.current.type == TokenType.COMMA:
							self.advance()

					self.expect(TokenType.RPAREN)
					expression = node(token, FunctionCall, expression, args)
				case TokenType.DOT:
					self.advance()
					expression = node(token, MemberAccess, expression, self.expect(TokenType.IDENT).value)
				case _:
					return expression

	def parse_primary(self) -> Node:
		token = self.current
		match token.type:
			case TokenType.NUMBER:
				return node(self.advance(), Literal, token.value)
			case TokenType.STRING:
				return node(self.advance(), Literal, token.value)
			case TokenType.BOOL:
				return node(self.advance(), Literal, token.value)
			case TokenType.IDENT:
				return node(self.advance(), Identifier, token.value)
			case TokenType.LPAREN:
				self.advance()
				expression = self.parse_expression()
				self.expect(TokenType.RPAREN)
				return expression
		raise self.error(StarchSyntaxError, f"unexpected token {token.type}")
