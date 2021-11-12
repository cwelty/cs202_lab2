#include "types.h"

#define START_STATE 0xACE1u

ushort rng(ushort upperLimit) {

    static ushort start_state = START_STATE;
    ushort lfsr;
    ushort bit;
    ushort i = 0;
    int winningNumber;

    if (start_state == 0) {
        start_state = start_state + 1;
    }

    lfsr = start_state;
    start_state = start_state + 1;

    do {
        bit = ((lfsr >> 0) ^ (lfsr >> 2) ^ (lfsr >> 3) ^ (lfsr >> 5));
        lfsr = (lfsr >> 1) | (bit << 15);
        i++;
    } while (i < upperLimit);

    winningNumber = lfsr % upperLimit;
    //printf("winning number: %d\n", winningNumber);
    return winningNumber;
}