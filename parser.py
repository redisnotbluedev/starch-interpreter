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
class Parameter(Node):
	name: str
	type: str | None
	default: Node | None

@dataclass(repr=False)
class VarDeclaration(Node):
	name: str
	type: str | None
	value: Node
	mutable: bool

@dataclass(repr=False)
class DerivedVariable(Node):
	name: str
	type: str | None
	value: Node
	dependencies: set[str]

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
	member: str

@dataclass(repr=False)
class ExpressionStatement(Node):
	expression: Node

@dataclass(repr=False)
class UnaryOp(Node):
	operator: TokenType
	operand: Node

@dataclass(repr=False)
class BinaryOp(Node):
	operator: TokenType
	left: Node
	right: Node

@dataclass(repr=False)
class Lambda(Node):
	params: list[Parameter]
	body: list[Node]

class Break(Node): ...
class Continue(Node): ...

@dataclass(repr=False)
class Return(Node):
	value: Node | None

@dataclass(repr=False)
class Throw(Node):
	exception: Node

@dataclass(repr=False)
class Using(Node):
	modules: list[str]

@dataclass(repr=False)
class ImportFrom(Node):
	module: str
	names: list[str]

@dataclass(repr=False)
class IfStatement(Node):
	condition: Node
	then_block: list[Node]
	elif_branches: list[tuple[Node, list[Node]]]
	else_block: list[Node] | None

@dataclass(repr=False)
class WhileLoop(Node):
	condition: Node
	block: list[Node]

@dataclass(repr=False)
class ForLoop(Node):
	variable: str
	collection: Node
	block: list[Node]

@dataclass(repr=False)
class WatchStatement(Node):
	variable: str
	block: list[Node]

@dataclass(repr=False)
class Assign(Node):
	variable: Node
	value: Node

@dataclass(repr=False)
class FunctionDeclaration(Node):
	name: str
	params: list[Parameter]
	type: str | None
	block: list[Node]

@dataclass(repr=False)
class MatchCase(Node):
	patterns: list[Node]
	block: list[Node]

@dataclass(repr=False)
class MatchStatement(Node):
	expression: Node
	cases: list[MatchCase]

@dataclass(repr=False)
class TryStatement(Node):
	body: list[Node]
	catch_variable: str | None
	catch_body: list[Node]
	finally_body: list[Node]

@dataclass(repr=False)
class ClassDeclaration(Node):
	name: str
	parent: str | None
	fields: list[VarDeclaration]
	methods: list[FunctionDeclaration]
	watchers: list[WatchStatement]
	derivatives: list[DerivedVariable]

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

	def is_lambda(self) -> bool:
		pos = self.pos + 1  # skip LPAREN
		depth = 1
		while pos < len(self.tokens):
			match self.tokens[pos].type:
				case TokenType.LPAREN:
					depth += 1
				case TokenType.RPAREN:
					depth -= 1
					if depth == 0:
						return self.tokens[pos + 1].type == TokenType.FAT_ARROW
			pos += 1
		return False

	def parse_args(self) -> list[Node]:
		args = []
		while self.current.type != TokenType.RPAREN:
			args.append(self.parse_expression())
			if self.current.type == TokenType.COMMA:
				self.advance()
		return args

	def parse_params(self) -> list[Parameter]:
		params = []
		while self.current.type != TokenType.RPAREN:
			name = self.expect(TokenType.IDENT)
			type = None
			default = None
			if self.current.type == TokenType.COLON:
				self.advance()
				type = self.expect(TokenType.IDENT).value
			if self.current.type == TokenType.OR:
				self.advance()
				default = self.parse_expression()
			params.append(node(name, Parameter, name.value, type, default))
			if self.current.type == TokenType.COMMA:
				self.advance()
		return params

	def find_identifiers(self, node: Node) -> set[str]:
		match node:
			case Identifier(name=name):
				return {name}
			case BinaryOp(left=left, right=right):
				return self.find_identifiers(left) | self.find_identifiers(right)
			case UnaryOp(operand=operand):
				return self.find_identifiers(operand)
			case FunctionCall(callee=callee, args=args):
				deps = self.find_identifiers(callee)
				for arg in args:
					deps |= self.find_identifiers(arg)
				return deps
			case MemberAccess(callee=callee):
				return self.find_identifiers(callee)
			case Literal():
				return set()
			case _:
				return set()

	def parse(self) -> Program:
		statements = []

		while self.current.type != TokenType.EOF:
			statements.append(self.parse_statement())

		return Program(statements)

	def parse_block(self) -> list[Node]:
		self.expect(TokenType.LBRACE)
		statements = []
		while self.current.type != TokenType.RBRACE:
			statements.append(self.parse_statement())
		self.expect(TokenType.RBRACE)
		return statements

	def parse_statement(self) -> Node:
		match self.current.type:
			case TokenType.VAR | TokenType.CONST:
				return self.parse_var_decl()
			case TokenType.DERIVE:
				return self.parse_derive()
			case TokenType.IF:
				return self.parse_if()
			case TokenType.WHILE:
				return self.parse_while()
			case TokenType.FOR:
				return self.parse_for()
			case TokenType.WATCH:
				return self.parse_watch()
			case TokenType.BREAK:
				statement = node(self.advance(), Break)
				self.terminate()
				return statement
			case TokenType.CONTINUE:
				statement = node(self.advance(), Continue)
				self.terminate()
				return statement
			case TokenType.RETURN:
				token = self.advance()
				expression = None
				if self.current.type != TokenType.SEMICOLON:
					expression = self.parse_expression()
				self.terminate()
				return node(token, Return, expression)
			case TokenType.THROW:
				token = self.advance()
				expression = self.parse_expression()
				self.terminate()
				return node(token, Throw, expression)
			case TokenType.USING:
				token = self.advance()
				names = [self.expect(TokenType.IDENT)]
				while self.current.type == TokenType.COMMA:
					self.advance()
					names.append(self.expect(TokenType.IDENT))

				if self.current.type == TokenType.FROM:
					self.advance()
					module = self.expect(TokenType.IDENT)
					self.terminate()
					return node(token, ImportFrom, module, names)

				self.terminate()
				return node(token, Using, names)
			case TokenType.FUNCTION:
				return self.parse_function()
			case TokenType.MATCH:
				return self.parse_match()
			case TokenType.TRY:
				return self.parse_try()
			case TokenType.CLASS:
				# Oh boy. Ohhhhhh boy.
				return self.parse_class()
			case _:
				return self.parse_expression_statement()

	def parse_var_decl(self) -> VarDeclaration:
		token = self.expect(TokenType.VAR)

		name = self.expect(TokenType.IDENT).value
		type = None

		if self.current.type == TokenType.COLON:
			self.advance()
			type = self.expect(TokenType.IDENT).value

		self.expect(TokenType.ASSIGN)
		value = self.parse_expression()

		self.terminate()

		return node(token, VarDeclaration, name, type, value, token.type == TokenType.VAR)

	def parse_derive(self) -> DerivedVariable:
		token = self.expect(TokenType.DERIVE)
		name = self.expect(TokenType.IDENT).value
		type = None

		if self.current.type == TokenType.COLON:
			self.advance()
			type = self.expect(TokenType.IDENT).value

		self.expect(TokenType.ASSIGN)
		value = self.parse_expression()
		self.terminate()

		dependencies = self.find_identifiers(value)
		return node(token, DerivedVariable, name, type, value, dependencies)

	def parse_if(self) -> IfStatement:
		token = self.expect(TokenType.IF)
		condition = self.parse_expression()
		then = self.parse_block()

		branches = []
		while self.current.type == TokenType.ELIF:
			self.advance()
			branches.append((
				self.parse_expression(),
				self.parse_block()
			))

		else_block = None
		if self.current.type == TokenType.ELSE:
			self.advance()
			else_block = self.parse_block()

		return node(token, IfStatement, condition, then, branches, else_block)

	def parse_while(self) -> WhileLoop:
		token = self.expect(TokenType.WHILE)
		return node(token, WhileLoop, self.parse_expression(), self.parse_block())

	def parse_for(self) -> ForLoop:
		token = self.expect(TokenType.FOR)
		identifier = self.expect(TokenType.IDENT)
		self.expect(TokenType.IN)
		return node(token, ForLoop, identifier, self.parse_expression(), self.parse_block())

	def parse_watch(self) -> WatchStatement:
		token = self.current
		self.expect(TokenType.WATCH)
		identifier = self.expect(TokenType.IDENT).value
		return node(token, WatchStatement, identifier, self.parse_block())

	def parse_function(self) -> FunctionDeclaration:
		token = self.expect(TokenType.FUNCTION)
		name = self.expect(TokenType.IDENT).value
		self.expect(TokenType.LPAREN)
		params = self.parse_params()
		self.expect(TokenType.RPAREN)

		type = None
		if self.current.type == TokenType.ARROW:
			self.advance()
			type = self.expect(TokenType.IDENT).value

		return node(token, FunctionDeclaration, name, params, type, self.parse_block())

	def parse_match(self) -> MatchStatement:
		token = self.advance()
		identifier = self.expect(TokenType.IDENT)
		variable = node(identifier, Identifier, identifier.value)
		self.expect(TokenType.LBRACE)
		cases = []
		while self.current.type == TokenType.CASE:
			case = self.advance()
			patterns = [self.parse_expression()]
			while self.current.type == TokenType.COMMA:
				# double while loop is CRAZYYY
				self.advance()
				patterns.append(self.parse_expression())
			cases.append(node(case, MatchCase, patterns, self.parse_block()))
		self.expect(TokenType.RBRACE)
		return node(token, MatchStatement, variable, cases)

	def parse_try(self) -> TryStatement:
		token = self.advance()
		block = self.parse_block()
		catch_variable = None
		catch_block = []
		finally_block = None

		if self.current.type == TokenType.CATCH:
			self.advance()
			self.expect(TokenType.LPAREN)
			catch_variable = self.expect(TokenType.IDENT).value
			self.expect(TokenType.RPAREN)
			catch_block = self.parse_block()

		if self.current.type == TokenType.FINALLY:
			self.advance()
			finally_block = self.parse_block()

		if not (catch_block or finally_block):
			raise self.error(StarchSyntaxError, "expected 'catch' or 'finally' block")

		return node(token, TryStatement, block, catch_variable, catch_block, finally_block)

	def parse_class(self) -> ClassDeclaration:
		token = self.advance()
		name = self.expect(TokenType.IDENT).value
		parent = None

		if self.current.type == TokenType.IS:
			self.advance()
			parent = self.expect(TokenType.IDENT).value

		fields, methods, watchers, derivatives = [], [], [], []
		for statement in self.parse_block():
			match statement:
				case VarDeclaration():
					fields.append(statement)
				case FunctionDeclaration():
					methods.append(statement)
				case WatchStatement():
					watchers.append(statement)
				case DerivedVariable():
					derivatives.append(statement)
				case _:
					raise StarchSyntaxError("unexpected statement in class body", statement.line, statement.source_line, statement.col, self.file)
		return node(token, ClassDeclaration, name, parent, fields, methods, watchers, derivatives)

	def parse_expression_statement(self) -> ExpressionStatement:
		token = self.current
		expression = self.parse_expression()

		if self.current.type == TokenType.ASSIGN:
			if not isinstance(expression, Identifier | MemberAccess):
				raise self.error(StarchSyntaxError, "invalid assignment target")

			self.advance()
			value = self.parse_expression()
			self.terminate()
			return node(token, Assign, expression, value)

		if self.current.type in (TokenType.PLUS_ASSIGN, TokenType.MINUS_ASSIGN, TokenType.STAR_ASSIGN, TokenType.SLASH_ASSIGN):
			if not isinstance(expression, Identifier | MemberAccess):
				raise self.error(StarchSyntaxError, "invalid assignment target")

			operator = {
				TokenType.PLUS_ASSIGN: TokenType.PLUS,
				TokenType.MINUS_ASSIGN: TokenType.MINUS,
				TokenType.STAR_ASSIGN: TokenType.STAR,
				TokenType.SLASH_ASSIGN: TokenType.SLASH
			}[self.advance().type]
			value = self.parse_expression()
			self.terminate()
			return node(token, Assign, expression, node(token, BinaryOp, operator, expression, value))

		self.terminate()
		return node(token, ExpressionStatement, expression)

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

		while self.current.type in (TokenType.EQ, TokenType.NEQ, TokenType.GT, TokenType.GTE, TokenType.LT, TokenType.LTE, TokenType.APPROX, TokenType.IN, TokenType.IS, TokenType.NOT):
			token = self.current
			if token.type == TokenType.NOT and self.peek().type == TokenType.IN:
				self.advance()
				self.advance()
				right = self.parse_concat()
				left = node(token, UnaryOp, TokenType.NOT, node(token, BinaryOp, TokenType.IN, left, right))
			elif token.type == TokenType.IS:
				self.advance()
				if self.current.type == TokenType.NOT:
					self.advance()
					type = self.expect(TokenType.IDENT).value
					left = node(token, UnaryOp, TokenType.NOT, node(token, BinaryOp, TokenType.IS, left, type))
				else:
					type = self.expect(TokenType.IDENT).value
					left = node(token, BinaryOp, TokenType.IS, left, type)
			else:
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
				if self.is_lambda():
					self.advance()
					params = self.parse_params()
					self.expect(TokenType.RPAREN)
					self.expect(TokenType.FAT_ARROW)
					body = self.parse_block()
					return node(token, Lambda, params, body)
				self.advance()
				expression = self.parse_expression()
				self.expect(TokenType.RPAREN)
				return expression
		raise self.error(StarchSyntaxError, f"unexpected token {token.type}")
