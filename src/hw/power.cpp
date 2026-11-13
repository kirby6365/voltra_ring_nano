#include "power.h"

#include <Arduino.h>

#include "driver/gpio.h"
#include "driver/rtc_io.h"
#include "esp_sleep.h"

#include "board_pins.h"
#include "oled.h"

namespace {
constexpr uint32_t RELEASE_DEBOUNCE_MS = 50;

void release_holds()
{
    gpio_hold_dis((gpio_num_t)PIN_ENC_B);
    const int lp_pins[] = {PIN_ENC_A, PIN_BUTTON};
    for (int pin : lp_pins) {
        rtc_gpio_hold_dis((gpio_num_t)pin);
        rtc_gpio_deinit((gpio_num_t)pin);   // back to the digital pad
    }
}

/** Wait until the button has been up for RELEASE_DEBOUNCE_MS. */
void wait_for_release()
{
    uint32_t up_since = 0;
    for (;;) {
        if (digitalRead(PIN_BUTTON) == HIGH) {
            if (!up_since) up_since = millis();
            else if (millis() - up_since >= RELEASE_DEBOUNCE_MS) return;
        } else {
            up_since = 0;
        }
        delay(5);
    }
}

[[noreturn]] void sleep_now()
{
    // The encoder's pull-ups would stay on through deep sleep and draw current through
    // whichever contact the wheel rests on. A is an LP pad: cut it off. B is a digital
    // pad: float it and hold it that way.
    rtc_gpio_isolate((gpio_num_t)PIN_ENC_A);
    gpio_set_direction((gpio_num_t)PIN_ENC_B, GPIO_MODE_INPUT);
    gpio_set_pull_mode((gpio_num_t)PIN_ENC_B, GPIO_FLOATING);
    gpio_hold_en((gpio_num_t)PIN_ENC_B);

    // Wake on the button alone: pulled up by the LP domain, waking when pressed to GND.
    esp_sleep_disable_wakeup_source(ESP_SLEEP_WAKEUP_ALL);
    rtc_gpio_init((gpio_num_t)PIN_BUTTON);
    rtc_gpio_set_direction((gpio_num_t)PIN_BUTTON, RTC_GPIO_MODE_INPUT_ONLY);
    rtc_gpio_pullup_en((gpio_num_t)PIN_BUTTON);
    rtc_gpio_pulldown_dis((gpio_num_t)PIN_BUTTON);
    esp_sleep_pd_config(ESP_PD_DOMAIN_RTC_PERIPH, ESP_PD_OPTION_ON);   // keeps that pull-up
    esp_sleep_enable_ext1_wakeup_io(1ULL << PIN_BUTTON, ESP_EXT1_WAKEUP_ANY_LOW);
    esp_deep_sleep_start();
}
}  // namespace

void power_boot_check()
{
    if (esp_sleep_get_wakeup_cause() != ESP_SLEEP_WAKEUP_EXT1) {
        release_holds();
        return;
    }
    // Woken by the button. The screen stays dark (the OLED is still asleep) until the
    // button has been held long enough.
    rtc_gpio_deinit((gpio_num_t)PIN_BUTTON);
    pinMode(PIN_BUTTON, INPUT_PULLUP);
    uint32_t up_since = 0;
    while (millis() < POWER_ON_HOLD_MS) {
        if (digitalRead(PIN_BUTTON) == HIGH) {
            if (!up_since) up_since = millis();
            else if (millis() - up_since >= RELEASE_DEBOUNCE_MS) sleep_now();   // let go too soon
        } else {
            up_since = 0;
        }
        delay(5);
    }
    release_holds();
}

void power_off()
{
    // Sleep only once the button is up, or its low level would wake the chip straight away.
    wait_for_release();
    oled_power_off();
    sleep_now();
}
