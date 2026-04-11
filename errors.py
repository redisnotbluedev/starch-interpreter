class StarchError(Exception):
	def __init__(self, message: str, line: int = 0, context: str | None = None, col: int | None = None, file: str = "<starch-input>"):
		self.line = line

		if context:
			text = f"File '{file}', line {line}\n\t{context}"
			if col:
				text += "\n\t" + " " * (col - 1) + "^"
		else:
			text = f"File '{file}', line {line}"

		text += f"\n{self.__class__.__name__.replace("Starch", "")}: {message}"
		super().__init__(text)

class StarchSyntaxError(StarchError): ...
class StarchTypeError(StarchError): ...
