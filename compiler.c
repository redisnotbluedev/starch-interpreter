#include <stdio.h>
#include <stdlib.h>
#include "common.h"
#include "compiler.h"
#include "scanner.h"

#ifdef DEBUG_PRINT_CODE
#include "debug.h"
#endif

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

// A function that takes nothing and returns nothing
typedef void (*ParseFn)();

typedef struct {
	// Function for prefix
	ParseFn prefix;
	// Function for infix
	ParseFn infix;
	// Its precedence
	Precedence precedence;
} ParseRule;

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

// Really self-explanatory
// Is anyone reading these?
static void endCompiler() {
	emitReturn();
	#ifdef DEBUG_PRINT_CODE
		if (!parser.hadError) {
			disassembleChunk(currentChunk(), "code");
		}
	#endif
}

// Forward declarations to handle recursive grammar
static void expression();
static ParseRule* getRule(TokenType type);
static void parsePrecedence(Precedence precedence);

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

ParseRule rules[] = {
	[TOKEN_LEFT_PAREN]    = {grouping, NULL,   PREC_NONE},
	[TOKEN_RIGHT_PAREN]   = {NULL,     NULL,   PREC_NONE},
	[TOKEN_LEFT_BRACE]    = {NULL,     NULL,   PREC_NONE}, 
	[TOKEN_RIGHT_BRACE]   = {NULL,     NULL,   PREC_NONE},
	[TOKEN_COMMA]         = {NULL,     NULL,   PREC_NONE},
	[TOKEN_DOT]           = {NULL,     NULL,   PREC_NONE},
	[TOKEN_MINUS]         = {unary,    binary, PREC_TERM},
	[TOKEN_PLUS]          = {NULL,     binary, PREC_TERM},
	[TOKEN_SEMICOLON]     = {NULL,     NULL,   PREC_NONE},
	[TOKEN_SLASH]         = {NULL,     binary, PREC_FACTOR},
	[TOKEN_STAR]          = {NULL,     binary, PREC_FACTOR},
	[TOKEN_BANG]          = {NULL,     NULL,   PREC_NONE},
	[TOKEN_BANG_EQUAL]    = {NULL,     NULL,   PREC_NONE},
	[TOKEN_EQUAL]         = {NULL,     NULL,   PREC_NONE},
	[TOKEN_EQUAL_EQUAL]   = {NULL,     NULL,   PREC_NONE},
	[TOKEN_GREATER]       = {NULL,     NULL,   PREC_NONE},
	[TOKEN_GREATER_EQUAL] = {NULL,     NULL,   PREC_NONE},
	[TOKEN_LESS]          = {NULL,     NULL,   PREC_NONE},
	[TOKEN_LESS_EQUAL]    = {NULL,     NULL,   PREC_NONE},
	[TOKEN_IDENTIFIER]    = {NULL,     NULL,   PREC_NONE},
	[TOKEN_STRING]        = {NULL,     NULL,   PREC_NONE},
	[TOKEN_NUMBER]        = {number,   NULL,   PREC_NONE},
	[TOKEN_AND]           = {NULL,     NULL,   PREC_NONE},
	[TOKEN_CLASS]         = {NULL,     NULL,   PREC_NONE},
	[TOKEN_ELSE]          = {NULL,     NULL,   PREC_NONE},
	[TOKEN_FALSE]         = {NULL,     NULL,   PREC_NONE},
	[TOKEN_FOR]           = {NULL,     NULL,   PREC_NONE},
	[TOKEN_FUN]           = {NULL,     NULL,   PREC_NONE},
	[TOKEN_IF]            = {NULL,     NULL,   PREC_NONE},
	[TOKEN_NIL]           = {NULL,     NULL,   PREC_NONE},
	[TOKEN_OR]            = {NULL,     NULL,   PREC_NONE},
	[TOKEN_PRINT]         = {NULL,     NULL,   PREC_NONE},
	[TOKEN_RETURN]        = {NULL,     NULL,   PREC_NONE},
	[TOKEN_SUPER]         = {NULL,     NULL,   PREC_NONE},
	[TOKEN_THIS]          = {NULL,     NULL,   PREC_NONE},
	[TOKEN_TRUE]          = {NULL,     NULL,   PREC_NONE},
	[TOKEN_VAR]           = {NULL,     NULL,   PREC_NONE},
	[TOKEN_WHILE]         = {NULL,     NULL,   PREC_NONE},
	[TOKEN_ERROR]         = {NULL,     NULL,   PREC_NONE},
	[TOKEN_EOF]           = {NULL,     NULL,   PREC_NONE},
};

static void parsePrecedence(Precedence precedence) {
	advance();
	// Get the prefix rule
	ParseFn prefixRule = getRule(parser.previous.type)->prefix;
	// If there's no prefix rule, it's a syntax error
	if (prefixRule == NULL) {
		error("Expect expression.");
		return;
	}

	prefixRule();

	// Stop if the token is too low precendence, or isn't an infix operator
	while (precedence <= getRule(parser.current.type)->precedence) {
		advance();
		// Get the infix rule
		ParseFn infixRule = getRule(parser.previous.type)->infix;
		// Run it
		infixRule();
	}
}

static ParseRule* getRule(TokenType type) {
	// Return the rule at the given index
	return &rules[type];
}

static void binary() {
	TokenType operatorType = parser.previous.type;
	ParseRule* rule = getRule(operatorType);
	parsePrecedence((Precedence)(rule->precedence + 1));

	switch (operatorType) {
		case TOKEN_PLUS:   emitByte(OP_ADD); break;
		case TOKEN_MINUS:  emitByte(OP_SUBTRACT); break;
		case TOKEN_STAR:   emitByte(OP_MULTIPLY); break;
		case TOKEN_SLASH:  emitByte(OP_DIVIDE); break;
		default: return; // Unreachable.
	}
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