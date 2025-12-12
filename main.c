#include "common.h"
#include "chunk.h"
#include "debug.h"
#include "vm.h"

int main(int argc, const char* argv[]) {
	initVM();

	// Create & init chunk
	Chunk chunk;
	initChunk(&chunk);

	// CONSTANT 1.2
	int constant = addConstant(&chunk, 1.2);
	// 123 is the line number, a placeholder,
	// because this doesn't have a parser yet
	writeChunk(&chunk, OP_CONSTANT, 123);
	writeChunk(&chunk, constant, 123);

	// hand-compiling is tedious
	constant = addConstant(&chunk, 3.4);
	writeChunk(&chunk, OP_CONSTANT, 123);
	writeChunk(&chunk, constant, 123);

	writeChunk(&chunk, OP_ADD, 123);

	constant = addConstant(&chunk, 5.6);
	writeChunk(&chunk, OP_CONSTANT, 123);
	writeChunk(&chunk, constant, 123);

	writeChunk(&chunk, OP_DIVIDE, 123);

	// Negate it
	writeChunk(&chunk, OP_NEGATE, 123);

	// Return the constant value
	// 123 is the same line number as before
	writeChunk(&chunk, OP_RETURN, 123);

	// Debug the chunk
	disassembleChunk(&chunk, "test chunk");

	// Run the chunk
	interpret(&chunk);

	freeVM();
	// bye bye chunk
	freeChunk(&chunk);

	return 0;
}