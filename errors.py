class StarchError(Exception):
	def __init__(self, type: str, message: str, line: int = 0, context: str | None = None):
		self.line = line
		if context:
			text = f"{type} on line {line}:\n\t{context}\n{message}"
		else:
			text = f"{type} on line {line}: {message}"
		super().__init__(text)

class StarchSyntaxError(StarchError):
	def __init__(self, message: str, line: int = 0, context: str | None = None):
		super().__init__("SyntaxError", message, line, context)
