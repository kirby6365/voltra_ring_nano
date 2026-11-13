/*
 * Voltra Ring Nano - BLE remote for the Beyond Power Voltra I
 * Target: Seeed XIAO ESP32-C6 with a 0.49" 64x32 OLED, a scroll wheel and a button
 */
#include <Arduino.h>

#include "hw/button.h"
#include "hw/knob.h"
#include "hw/oled.h"
#include "hw/power.h"
#include "ui/ui.h"
#include "voltra/voltra_client.h"

void setup()
{
    // Woken from power off: goes straight back to sleep unless the button is held.
    power_boot_check();

    Serial.begin(115200);
    log_i("Voltra Ring Nano starting (free heap %u)", (unsigned)ESP.getFreeHeap());

    oled_init();
    knob_init();
    button_init();

    // The client must come up before the UI: ui_init() reads the current device state,
    // and Client::begin() is what creates the mutex guarding it.
    voltra::Client::instance().begin();
    ui_init();
    log_i("ready (free heap %u)", (unsigned)ESP.getFreeHeap());
}

void loop()
{
    ui_poll();
    delay(UI_POLL_MS);
}
