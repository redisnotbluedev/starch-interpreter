#include <stdio.h>
#include "common.h"
#include "compiler.h"
#include "scanner.h"

void compile(const char* source) {
	initScanner(source);
	// Current line
	int line = -1;
	// Loop indefinitely
	for (;;) {
		/* Scan a token
			Since lox requires only a single token for lookahead, we don't need
			to scan everything at the same time. Instead the compiler only gets a single
			token whenever it needs to. This saves memory and makes the code simpler. */
		Token token = scanToken();
		// Check if the token's is another line, usually the next line
		if (token.line != line) {
			printf("%4d ", token.line);
			line = token.line;
		} else {
			printf("   | ");
		}
		/* Columns:
			1: Line number
			2: Numeric type
			3: Lexeme */
		printf("%2d '%.*s'\n", token.type, token.length, token.start); 

		// Stop on an EOF token
		if (token.type == TOKEN_EOF) break;
	}
}