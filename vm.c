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
	#define BINARY_OP(op) do { \
		// b is first, because the first number (a) will be lower \
		// down in the stack than b, due to the execution order \
		double b = pop(); \
		double a = pop(); \
		push(a op b); \
		// The do-while trick is strange \
		// It prevents weird cases in macros though \
	} while (false)

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
			case OP_CONSTANT: {
				// Create a constant
				// This is pushed onto the stack
				Value constant = READ_CONSTANT();
				push(constant);
				break;
			}
			// Binary operations
			// Add, subtract, multiply and divide
			// Who knew you could pass an operator to a macro?
			case OP_ADD:      BINARY_OP(+); break;
			case OP_SUBTRACT: BINARY_OP(-); break;
			case OP_MULTIPLY: BINARY_OP(*); break;
			case OP_DIVIDE:   BINARY_OP(/); break;
			case OP_NEGATE: {
				// Negate a value
				// Pop from the stack and push the opposite value.
				// 1.2 → -1.2
				push(-pop());
				break;
			}
			case OP_RETURN: {
				// Return a value from a function
				// For now, since there are no functions,
				// this prints out the value
				printValue(pop());
				printf("\n");
				return INTERPRET_OK;
			}
		}
	}

	#undef READ_BYTE
	#undef READ_CONSTANT
	#undef BINARY_OP
}
InterpretResult interpret(Chunk* chunk) {
	vm.chunk = chunk;
	vm.ip = vm.chunk->code;
	return run();
}