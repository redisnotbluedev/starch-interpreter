#ifndef clox_value_h

#define clox_value_h
#include "common.h"

typedef double Value;
typedef struct {
	// The space in the array
	int capacity;
	// The number of items in the array
	int count;
	// The array
	Value* values;
} ValueArray;

void initValueArray(ValueArray* array);
void writeValueArray(ValueArray* array, Value value);
void freeValueArray(ValueArray* array);
void printValue(Value value);

#endif