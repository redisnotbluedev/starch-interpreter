#ifndef clox_debug_h

#define clox_debug_h
#include "chunk.h"

// Disassemble a chunk
void disassembleChunk(Chunk* chunk, const char* name);
// Disassemble an instruction
int disassembleInstruction(Chunk* chunk, int offset);

#endif