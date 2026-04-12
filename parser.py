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
	operator: TokenType
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

	def parse_args(self) -> list[Node]:
		args = []
		while self.current.type != TokenType.RPAREN:
			args.append(self.parse_expression())
			if self.current.type == TokenType.COMMA:
				self.advance()
		return args

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
		return self.parse_pipeline()

	def parse_pipeline(self) -> Node:
		left = self.parse_or()

		while self.current.type == TokenType.PIPELINE:
			token = self.current
			self.advance()

			if self.current.type == TokenType.DOT:
				# x ~> .method(args)
				self.advance()
				member = self.expect(TokenType.IDENT)

				if self.current.type == TokenType.LPAREN:
					self.advance()
					args = self.parse_args()
					self.expect(TokenType.RPAREN)
					left = node(token, FunctionCall, node(member, MemberAccess, left, member.value), args)
				else:
					left = node(token, MemberAccess, left, member.value)

			else:
				# x ~> method(args)
				callee = self.expect(TokenType.IDENT)
				args = []
				if self.current.type == TokenType.LPAREN:
					self.advance()
					args = self.parse_args()
					self.expect(TokenType.RPAREN)
				args.insert(0, left)
				left = node(token, FunctionCall, node(callee, Identifier, callee.value), args)

		return left

	def parse_or(self) -> Node:
		left = self.parse_and()

		while self.current.type == TokenType.OR:
			token = self.current
			self.advance()
			right = self.parse_and()
			left = node(token, BinaryOp, TokenType.OR, left, right)

		return left

	def parse_and(self) -> Node:
		left = self.parse_not()

		while self.current.type == TokenType.AND:
			token = self.current
			self.advance()
			right = self.parse_not()
			left = node(token, BinaryOp, TokenType.AND, left, right)

		return left

	def parse_not(self) -> Node:
		token = self.current
		if token.type == TokenType.NOT:
			self.advance()
			return node(token, UnaryOp, TokenType.NOT, self.parse_not())

		return self.parse_comparison()

	def parse_comparison(self) -> Node:
		left = self.parse_concat()

		while self.current.type in (TokenType.EQ, TokenType.NEQ, TokenType.GT, TokenType.GTE, TokenType.LT, TokenType.LTE, TokenType.APPROX):
			token = self.current
			operator = self.advance().type
			right = self.parse_concat()
			left = node(token, BinaryOp, operator, left, right)

		return left

	def parse_concat(self) -> Node:
		left = self.parse_range()

		while self.current.type == TokenType.CONCAT:
			token = self.current
			self.advance()
			right = self.parse_range()
			left = node(token, BinaryOp, TokenType.CONCAT, left, right)

		return left

	def parse_range(self) -> Node:
		left = self.parse_additive()

		while self.current.type == TokenType.RANGE:
			token = self.current
			self.advance()
			right = self.parse_additive()
			left = node(token, BinaryOp, TokenType.RANGE, left, right)

		return left

	def parse_additive(self) -> Node:
		left = self.parse_multiplicative()

		while self.current.type in (TokenType.PLUS, TokenType.MINUS):
			token = self.current
			operator = self.advance().type
			right = self.parse_multiplicative()
			left = node(token, BinaryOp, operator, left, right)

		return left

	def parse_multiplicative(self) -> Node:
		left = self.parse_exponent()

		while self.current.type in (TokenType.STAR, TokenType.SLASH, TokenType.PERCENT):
			token = self.current
			operator = self.advance().type
			right = self.parse_exponent()
			left = node(token, BinaryOp, operator, left, right)

		return left

	def parse_exponent(self) -> Node:
		base = self.parse_unary()
		if self.current.type == TokenType.CARET:
			token = self.current
			self.advance()
			return node(token, BinaryOp, TokenType.CARET, base, self.parse_exponent())
		return base

	def parse_unary(self) -> Node:
		token = self.current
		if token.type == TokenType.MINUS:
			self.advance()
			return node(token, UnaryOp, TokenType.MINUS, self.parse_unary())

		return self.parse_call()

	def parse_call(self) -> Node:
		expression = self.parse_primary()

		while True:
			token = self.current

			match token.type:
				case TokenType.LPAREN:
					self.advance()
					args = self.parse_args()
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
			case TokenType.NUMBER | TokenType.FLOAT | TokenType.STRING | TokenType.BOOL:
				return node(self.advance(), Literal, token.value)
			case TokenType.IDENT:
				return node(self.advance(), Identifier, token.value)
			case TokenType.LPAREN:
				self.advance()
				expression = self.parse_expression()
				self.expect(TokenType.RPAREN)
				return expression
		raise self.error(StarchSyntaxError, f"unexpected token {token.type}")
