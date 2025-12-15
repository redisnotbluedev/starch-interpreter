#include <stdio.h>
#include <stdlib.h>
#include "common.h"
#include "compiler.h"
#include "scanner.h"

typedef struct {
	// Current token
	Token current;
	// Previous token
	Token previous;
	// Whether the parser's run into an error
	bool hadError;
	// panicMode supresses any extra errors, so only one error is outputted 
	bool panicMode;
} Parser;

typedef enum {
	PREC_NONE,
	PREC_ASSIGNMENT,  // =
	PREC_OR,          // or
	PREC_AND,         // and
	PREC_EQUALITY,    // == !=
	PREC_COMPARISON,  // < > <= >=
	PREC_TERM,        // + -
	PREC_FACTOR,      // * /
	PREC_UNARY,       // ! -
	PREC_CALL,        // . ()
  	PREC_PRIMARY
} Precedence;

Parser parser;
// The current chunk
Chunk* compilingChunk;

// Output the current chunk
/* This is a function because later the logic will
   be more messy and we'll need more than just a return */
static Chunk* currentChunk() {
	return compilingChunk;
}

static void errorAt(Token* token, const char* message) {
	// Supress more warnings if panic mode is on
	if (parser.panicMode) return;
	parser.panicMode = true;
	// Print out the error
	fprintf(stderr, "[line %d] Error", token->line);

	if (token->type == TOKEN_EOF) {
		fprintf(stderr, " at end");
	} else if (token->type == TOKEN_ERROR) {
		// Nothing.
	} else {
		fprintf(stderr, " at '%.*s'", token->length, token->start);
	}

	// Message
	fprintf(stderr, ": %s\n", message);
	parser.hadError = true;
}

// Create an error
static void error(const char* message) {
	errorAt(&parser.previous, message);
}

// Create an error at the current token
static void errorAtCurrent(const char* message) {
	errorAt(&parser.current, message);
}

// Advance to the next token
static void advance() {
	parser.previous = parser.current;

	// Repeat indefinitely
	for (;;) {
		// Get a token
		parser.current = scanToken();
		// If it not an error, finish
		if (parser.current.type != TOKEN_ERROR) break;
		// Otherwise create an error
		errorAtCurrent(parser.current.start);
	}
}

// Look for a token type, but raise an error if it's not there
static void consume(TokenType type, const char* message) {
	if (parser.current.type == type) {
		// Eat the token
		advance();
		return;
	}

	// Otherwise raise an error
	errorAtCurrent(message);
}

// Create bytecode
static void emitByte(uint8_t byte) {
	writeChunk(currentChunk(), byte, parser.previous.line);
}

// Create TWO bytes of bytecode
// Yes, TWO (2) whole bytes
// That's like my whole disk space
// Absolutely massive to be honest
// I mean I can't even count that high really
static void emitBytes(uint8_t byte1, uint8_t byte2) {
	emitByte(byte1);
	emitByte(byte2);
}

// Emit... a return token
// Pretty simple stuff lads, nothing to see here
static void emitReturn() {
	// The reason behind this is because OP_RETURN doesn't do return things right now
	// When we get functions this won't be needed
	emitByte(OP_RETURN);
}

static uint8_t makeConstant(Value value) {
	// Add the constant (:exploding_head:)
	// I don't remember writing this but hey if it works it works right
	int constant = addConstant(currentChunk(), value);
	// Can't fit
	if (constant > UINT8_MAX) {
		error("Too many constants in one chunk.");
		return 0;
	}

	return (uint8_t)constant;
}

static void emitConstant(Value value) {
	emitBytes(OP_CONSTANT, makeConstant(value));
}

// Compile a number
static void number() {
	// Assume this's already been consumed and stored
	// Convert to a double value
	double value = strtod(parser.previous.start, NULL);
	emitConstant(value);
}

static void unary() {
	TokenType operatorType = parser.previous.type;
	// Compile the operand
	parsePrecedence(PREC_UNARY); // pass in unary so you can nest unary ops

	// Emit the operator instruction
	switch (operatorType) {
		case TOKEN_MINUS: emitByte(OP_NEGATE); break;
		default: return; // unreachable
	}
}

static void parsePrecedence(Precedence precedence) {

}

// Really self-explanatory
// Is anyone reading these?
static void endCompiler() {
	emitReturn();
}

static void grouping() {
	expression();
	consume(TOKEN_RIGHT_PAREN, "Expect ')' after expression.");
}

// Compile an expression
static void expression() {
	// Parse the lowest level
	parsePrecedence(PREC_ASSIGNMENT);
}

// Bop it! Twist it! Pull it! Compile it!
// yeah ok ill stop
bool compile(const char* source, Chunk* chunk) {
	// initialise values
	initScanner(source);
	compilingChunk = chunk;

	parser.hadError = false;
	parser.panicMode = false;

	// Compile an expression since this is too dumb to handle statements
	// (yet)
	advance();
	expression();
	consume(TOKEN_EOF, "Expect end of expression.");

	// Clean up
	endCompiler();
	return !parser.hadError;
}