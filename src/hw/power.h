#pragma once

/**
 * Power off / on with the button: deep sleep, woken only by the button.
 *
 * In deep sleep the ESP32-C6 is down to its LP domain and just watches PIN_BUTTON (an LP
 * pad, through EXT1); the radio, CPU and flash are off and the OLED is in its sleep mode.
 * What is left is outside software control: the XIAO's 3.3 V regulator and charger, and the
 * OLED controller's standby current.
 */

/** Hold this long to power off (the screen shows OFF from BUTTON_CANCEL_MS on). */
constexpr unsigned POWER_OFF_HOLD_MS = 5000;
/** Hold this long, from waking, to power back on; a shorter press goes straight back to sleep. */
constexpr unsigned POWER_ON_HOLD_MS = 3000;

/**
 * Call first thing in setup(). After a cold boot it just releases the pins held during
 * sleep. After a button wake it keeps everything dark and waits: if the button is let go
 * before POWER_ON_HOLD_MS it sleeps again, otherwise it returns and the boot carries on
 * (with the button still down; the button driver ignores that press).
 */
void power_boot_check();

/** Wait for the button to be let go, turn the screen off, then deep sleep. Does not return. */
[[noreturn]] void power_off();
