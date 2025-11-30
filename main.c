#include "common.h"
#include "chunk.c"
#include "debug.c"

int main(int argc, const char* argv[]) {
	// Create & init chunk
	Chunk chunk;
	initChunk(&chunk);
	// use opcode RETURN in the chunk
	writeChunk(&chunk, OP_RETURN);

	disassembleChunk(&chunk, "test chunk");
	// bye bye chunk
	freeChunk(&chunk);

	return 0;
}