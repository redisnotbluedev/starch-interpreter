#ifndef clox_vm_h

#define clox_vm_h
#include "chunk.h"
#include "value.h"

#define STACK_MAX 256

typedef struct {
	Chunk* chunk;
	// The instruction pointer
	uint8_t* ip;
	// The stack
	Value stack[STACK_MAX];
	// This is a pointer to the next empty space, NOT the currently used one
	Value* stackTop;
} VM;

typedef enum {
	INTERPRET_OK,
	INTERPRET_COMPILE_ERROR,
	INTERPRET_RUNTIME_ERROR
} InterpretResult;

// Start the VM
void initVM();
// Delete the VM
void freeVM();
// Interpret a chunk
InterpretResult interpret(Chunk* chunk);
// Push a value onto the stack
void push(Value value);
// Pop a value from the stack
Value pop();

#endif