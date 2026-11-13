#pragma once
#include <stdint.h>

/**
 * 0.49" 64x32 monochrome OLED (SSD1306 or SSD1315) on I2C.
 *
 * Drawing goes into a 256-byte frame buffer laid out as the controller's RAM: four
 * 8-pixel pages of 64 columns, bit 0 the top row of each page. oled_flush() sends it, and
 * only when it differs from what was last sent.
 */
void oled_init();

void oled_clear();
void oled_pixel(int x, int y, bool on);
void oled_fill_rect(int x, int y, int w, int h, bool on);

/** Send the frame buffer to the panel if it changed. */
void oled_flush();

/** Panel brightness, 0-255 (the controller's contrast setting). */
void oled_set_brightness(uint8_t level);

/** Panel off and its charge pump stopped (a few uA), ready for deep sleep. */
void oled_power_off();
