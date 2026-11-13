#pragma once
#include <stdint.h>

/**
 * Scroll wheel input: the mouse-wheel encoder on PIN_ENC_A / PIN_ENC_B, read with pin
 * interrupts. It is not a clean quadrature encoder, so it is decoded detent by detent
 * (see knob.cpp for how it behaves). Define KNOB_INVERT=1 to flip the direction.
 */
void knob_init();

/** Detents turned since the last call (positive = wheel rolled up, towards the screen top). */
int knob_take_delta();
