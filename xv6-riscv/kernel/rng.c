#include <stdint.h>

/* These state variables must be initialised so that they are not all zero. */
uint64 w, x, y, z;

uint64 rng(void) 
{
    uint64 t = x;
    t ^= t << 11U;
    t ^= t >> 8U;
    x = y; y = z; z = w; 
    w ^= w >> 19U;
    w ^= t;
    return w;
}