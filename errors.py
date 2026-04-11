from abc import ABC, abstractmethod

class StarchError(ABC, Exception):
	def __init__(self, message: str, line: int = 0, context: str | None = None, col: int | None = None, file: str = "<starch-input>"):
		abstracts = getattr(self, "__abstractmethods__", set())

		if abstracts:
			methods = ", ".join(f"'{m}'" for m in abstracts)
			raise TypeError(
				f"Can't instantiate abstract class {self.__class__.__name__} "
				f"without an implementation for abstract method {methods}"
			)

		self.line = line

		if context:
			text = f"File '{file}', line {line}\n\t{context}"
			if col:
				text += "\n\t" + " " * (col - 1) + "^"
		else:
			text = f"File '{file}', line {line}"

		text += f"\n{self.get_type()}: {message}"
		super().__init__(text)

	@abstractmethod
	def get_type(self) -> str:
		pass

class StarchSyntaxError(StarchError):
	def get_type(self):
		return "SyntaxError"
