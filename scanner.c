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

static char advance() {
	// Increment
	scanner.current++;
	return scanner.current[-1];
}

static char peek() {
  	return *scanner.current;
}

static char peekNext() {
	// peek, but for the character AFTER the next
	if (isAtEnd()) return '\0';
	return scanner.current[1];
}

static bool match(char expected) {
	// No more characters
	if (isAtEnd()) return false;
	// Next character is wrong
	if (*scanner.current != expected) return false;
	// Otherwise, increment and continue
	scanner.current++;
	return true;
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

static void skipWhitespace() {
	// Repeat indefinitely
	for (;;) {
		// Check the next character
		char c = peek();
		switch (c) {
		// It's whitespace
		case ' ':
		case '\r':
		case '\t':
			advance();
			break;
		// Special case because we track lines
		case '\n':
			scanner.line++;
			advance();
			break;
		// I don't care if comments aren't whitespace, they might as well be
		case '/':
			if (peekNext() == '/') {
				// A comment goes until the end of a line
				while (peek() != '\n' && !isAtEnd()) advance();
			} else {
				return;
			}
			break;
		// It's meaningful
		default:
			return;
		}
	}
}

Token scanToken() {
	// lox is C-styled, so no whitespace is needed
	skipWhitespace();

	// Each call to the function scans a complete token
	scanner.start = scanner.current;

	if (isAtEnd()) return makeToken(TOKEN_EOF);

	char c = advance();
	switch (c) {
		// Single-character tokens
		case '(': return makeToken(TOKEN_LEFT_PAREN);
		case ')': return makeToken(TOKEN_RIGHT_PAREN);
		case '{': return makeToken(TOKEN_LEFT_BRACE);
		case '}': return makeToken(TOKEN_RIGHT_BRACE);
		case ';': return makeToken(TOKEN_SEMICOLON);
		case ',': return makeToken(TOKEN_COMMA);
		case '.': return makeToken(TOKEN_DOT);
		case '-': return makeToken(TOKEN_MINUS);
		case '+': return makeToken(TOKEN_PLUS);
		case '/': return makeToken(TOKEN_SLASH);
		case '*': return makeToken(TOKEN_STAR);

		// Two-character tokens
		case '!':
			return makeToken(
				match('=') ? TOKEN_BANG_EQUAL : TOKEN_BANG);
		case '=':
			return makeToken(
				match('=') ? TOKEN_EQUAL_EQUAL : TOKEN_EQUAL);
		case '<':
			return makeToken(
				match('=') ? TOKEN_LESS_EQUAL : TOKEN_LESS);
		case '>':
			return makeToken(
				match('=') ? TOKEN_GREATER_EQUAL : TOKEN_GREATER);
	}

	return errorToken("Unexpected character.");
}