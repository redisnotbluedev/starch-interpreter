#include "common.h"
#include "debug.h"
#include "vm.h"
#include <stdio.h>

VM vm;

static void resetStack() {
	vm.stackTop = vm.stack;
}
void initVM() {
	resetStack();
}
void freeVM() {}
void push(Value value) {
	*vm.stackTop = value;
	vm.stackTop++;
}
Value pop() {
	vm.stackTop--;
	return *vm.stackTop;
}
static InterpretResult run() {
	#define READ_BYTE() (*vm.ip++)
	#define READ_CONSTANT() (vm.chunk->constants.values[READ_BYTE()])

	for (;;) {
		#ifdef DEBUG_TRACE_EXECUTION
			// Debug
			printf("          ");
			// Print the stack
			for (Value* slot = vm.stack; slot < vm.stackTop; slot++) {
				printf("[");
				printValue(*slot);
				printf("]");
			}
			printf("\n");
			// Print the current chunk
			disassembleInstruction(vm.chunk,
								(int)(vm.ip - vm.chunk->code));
		#endif

		uint8_t instruction;
		switch (instruction = READ_BYTE()) {
			case OP_RETURN:
				// Return a value from a function
				// For now, since there are no functions,
				// this prints out the value
				printValue(pop());
				printf("\n");
				return INTERPRET_OK;
			case OP_CONSTANT: {
				// Create a constant
				// This is pushed onto the stack
				Value constant = READ_CONSTANT();
				push(constant);
				break;
			}
		}
	}

	#undef READ_BYTE
	#undef READ_CONSTANT
}
InterpretResult interpret(Chunk* chunk) {
	vm.chunk = chunk;
	vm.ip = vm.chunk->code;
	return run();
}