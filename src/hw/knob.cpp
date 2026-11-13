#include "knob.h"

#include <Arduino.h>

#include <atomic>

#include "driver/gpio.h"

#include "board_pins.h"

#ifndef KNOB_INVERT
#define KNOB_INVERT 0
#endif

/*
 * How the case's wheel encoder behaves (from an edge trace on the bench), with AB the
 * levels of A and B:
 *
 * - One detent rests at 11. The next rests where B switches, so it reads 01 or 00
 *   depending on just where it stops, and B can chatter there.
 * - Turning down, A falls first (11 -> 01), then B (-> 00), then both rise together
 *   (00 -> 11, within a few microseconds of each other).
 * - Turning up is the reverse: both fall together (11 -> 00), then B rises (-> 01), then A.
 *
 * A quadrature counter cannot follow this: it scores the near-simultaneous pair by which
 * contact closes first, so one direction came out 2 per detent and the other 1. Instead
 * this counts a detent each time the wheel leaves the 11 rest or comes back to it. Leaving
 * by A alone (to 01) is down, by B (to 10 or 00) is up; coming back from 01 (A rising) is
 * up, from 10 or 00 is down. Chatter at either detent comes in pairs that cancel out, and
 * so does B chattering between 01 and 00.
 */
namespace {
constexpr uint8_t REST = 0b11;   // AB
constexpr uint8_t A_LOW = 0b01;  // A = 0, B = 1: A has switched, B not yet

std::atomic<int> s_detents{0};
uint8_t s_ab = REST;   // touched only by the ISR once it is attached

inline uint8_t read_ab()
{
    return (uint8_t)((gpio_get_level((gpio_num_t)PIN_ENC_A) << 1) | gpio_get_level((gpio_num_t)PIN_ENC_B));
}

void ARDUINO_ISR_ATTR knob_isr()
{
    const uint8_t ab = read_ab();
    const uint8_t was = s_ab;
    if (ab == was) return;
    s_ab = ab;
    int d = 0;
    if (was == REST) d = (ab == A_LOW) ? -1 : 1;        // leaving: A alone = down, B = up
    else if (ab == REST) d = (was == A_LOW) ? 1 : -1;   // returning: A rising = up, B = down
    if (d) s_detents.fetch_add(KNOB_INVERT ? -d : d, std::memory_order_relaxed);
}
}  // namespace

void knob_init()
{
    // The encoder's common pin goes to GND.
    pinMode(PIN_ENC_A, INPUT_PULLUP);
    pinMode(PIN_ENC_B, INPUT_PULLUP);
    s_ab = read_ab();
    attachInterrupt(PIN_ENC_A, knob_isr, CHANGE);
    attachInterrupt(PIN_ENC_B, knob_isr, CHANGE);
}

int knob_take_delta()
{
    return s_detents.exchange(0, std::memory_order_relaxed);
}
