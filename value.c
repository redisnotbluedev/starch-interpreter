#include <stdio.h>

#include "memory.h"
#include "value.h"

// Initialise all values with zero
void initValueArray(ValueArray* array) {
	array->values = NULL;
	array->capacity = 0;
	array->count = 0;
}

// Write a value to the values array
void writeValueArray(ValueArray* array, Value value) {
	// can it fit?
	if (array->capacity < array->count + 1) {
		int oldCapacity = array->capacity;
		array->capacity = GROW_CAPACITY(oldCapacity);
		array->values = GROW_ARRAY(Value, array->values,
								oldCapacity, array->capacity);
	}

	array->values[array->count] = value;
	array->count++;
}

// Delete the array
void freeValueArray(ValueArray* array) {
	FREE_ARRAY(Value, array->values, array->capacity);
	initValueArray(array);
}

// Print a value
void printValue(Value value) {
	printf("%g", value);
}