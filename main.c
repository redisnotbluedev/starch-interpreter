#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "common.h"
#include "chunk.h"
#include "debug.h"
#include "vm.h"

static void repl() {
	char line[1024];
	for (;;) {
		printf("> ");

		// fgets loads one line into the line variable from stdin
		// This is limited to sizeof(line), so up to 1024 characters
		if (!fgets(line, sizeof(line), stdin)) {
			printf("\n");
			break;
		}

		interpret(line);
	}
}

static char* readFile(const char* path) {
	// Open the file
	FILE* file = fopen(path, "rb");
	// it failed to open, god knows why
	if (file == NULL) {
		fprintf(stderr, "Could not open file \"%s\".\n", path);
		exit(74);
	}

	// Go to the end
	fseek(file, 0L, SEEK_END);
	// Get the position (equivalently the filesize)
	size_t fileSize = ftell(file);
	// Go back to the start
	rewind(file);

	// Create an array with size fileSize + 1 (space for the null byte)
	char* buffer = (char*)malloc(fileSize + 1);
	// Can't allocate the memory to read the file
	// If this happens I think the user has bigger problems
	// This is likely to happen on my computer
	// (i have 5mb space left HELP)
	if (buffer == NULL) {
		fprintf(stderr, "Not enough memory to read \"%s\".\n", path);
		exit(74);
	}
	// Read the file into buffer
	size_t bytesRead = fread(buffer, sizeof(char), fileSize, file);
	if (bytesRead < fileSize) {
		fprintf(stderr, "Could not read file \"%s\".\n", path)
	}
	// Add a null terminator at the end
	buffer[bytesRead] = '\0';

	// Close the file
	fclose(file);
	return buffer;
}

static void runFile(const char* path) {
	// Read the file
	char* source = readFile(path);
	// Interpret it
	InterpretResult result = interpret(source);
	// Free the variable
	free(source);

	// Set exit codes
	if (result == INTERPRET_COMPILE_ERROR) exit(65);
	if (result == INTERPRET_RUNTIME_ERROR) exit(70);
}

int main(int argc, const char* argv[]) {
	initVM();

	// argv contains the file, so it'd look like this:
	// [clox, main.lox]
	// This means that we check for argc == 1 or 2, not 0 or 1
	if (argc == 1) {
		repl();
	} else if (argc == 2) {
		runFile(argv[1]);
	} else {
		// Semantics: print to stderr instead of the default stdout
		fprintf(stderr, "Usage: clox [path]\n");
	}

	freeVM();
	return 0;
}