#include <stdio.h>
#include <string.h>
#include "common.h"
#include "scanner.h"

typedef struct {
	// The start of the current lexeme
	const char* start;
	// The current character
	const char* current;
	// The line we're on
	int line;
} Scanner;

Scanner scanner;

void initScanner(const char* source) {
	scanner.start = source;
	scanner.current = source;
	scanner.line = 1;
}

static bool isAtEnd() {
	return *scanner.current == '\0';
}

static Token makeToken(TokenType type) {
	Token token;
	token.type = type;
	token.start = scanner.start;
	token.length = (int)(scanner.current - scanner.start);
	token.line = scanner.line;
	return token;
}

static Token errorToken(const char* message) {
	Token token;
	token.type = TOKEN_ERROR;
	token.start = message;
	token.length = (int)strlen(message);
	token.line = scanner.line;
	return token;
}

Token scanToken() {
	// Each call to the function scans a complete token
	scanner.start = scanner.current;

	if (isAtEnd()) return makeToken(TOKEN_EOF);

	return errorToken("Unexpected character.");
}