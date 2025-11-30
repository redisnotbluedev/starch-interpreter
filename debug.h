#ifndef clox_debug_h

#define clox_debug_h
#include "chunk.c"

void disassembleChunk(Chunk* chunk, const char* name);
void disassembleInstruction(Chunk* chunk, int offset);

#endif