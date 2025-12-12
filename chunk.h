#ifndef clox_chunk_h

#define clox_chunk_h
#include "common.h"
#include "value.h"

typedef enum {
	OP_CONSTANT,
	OP_RETURN,
} OpCode;

typedef struct {
	// Number of bytes in the chunk
	int count;
	// Remaining space in the variable array
	int capacity;
	// Array of bytes
  	uint8_t* code;
	int* lines;
	ValueArray constants;
} Chunk;

// Create an empty chunk
void initChunk(Chunk* chunk);
// Delete a chunk
void freeChunk(Chunk* chunk);
// Write a byte to a chunk
void writeChunk(Chunk* chunk, uint8_t byte, int line);
// Add a constant to a chunk
int addConstant(Chunk* chunk, Value value);

#endif