#include <stdlib.h>
#include "memory.h"

// Memory operations function
// If oldSize is 0 and newSize is non-zero, allocate a new block
// If oldSize is non-zero and newSize is 0, free the block
// If oldSize is non-zero and newSize is less than oldSize, shrink the allocation
// If oldSize is non-zero and newSize is more than oldSize, grow the allocation
void* reallocate(void* pointer, size_t oldSize, size_t newSize) {
	if (newSize == 0) {
		free(pointer);
		return NULL;
	}

	void* result = realloc(pointer, newSize);
	if (result == NULL) exit(1);
	return result;
}