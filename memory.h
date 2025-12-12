#ifndef clox_memory_h

#define clox_memory_h
#include "common.h"

// Grow the capacity by a factor of 2
// Start with a minimum of 8
#define GROW_CAPACITY(capacity) \
	((capacity) < 8 ? 8 : (capacity) * 2)

// Grow an array to a certain size
#define GROW_ARRAY(type, pointer, oldCount, newCount) \
	(type*)reallocate(pointer, sizeof(type) * (oldCount), \
		sizeof(type) * (newCount))

// Delete an array
#define FREE_ARRAY(type, pointer, oldCount) \
	reallocate(pointer, sizeof(type) * (oldCount), 0)

void* reallocate(void* pointer, size_t oldSize, size_t newSize);

#endif