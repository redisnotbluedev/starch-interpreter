#include "common.h"
#include "chunk.h"
#include "debug.h"

int main(int argc, const char* argv[]) {
	// Create & init chunk
	Chunk chunk;
	initChunk(&chunk);

	int constant = addConstant(&chunk, 1.2);
	writeChunk(&chunk, OP_CONSTANT);
	writeChunk(&chunk, constant);

	// use opcode RETURN in the chunk
	writeChunk(&chunk, OP_RETURN);

	disassembleChunk(&chunk, "test chunk");
	// bye bye chunk
	freeChunk(&chunk);

	return 0;
}