#include "oled.h"

#include <Arduino.h>
#include <Wire.h>
#include <string.h>

#include "board_pins.h"

namespace {
constexpr int PAGES = OLED_H / 8;
constexpr size_t FB_SIZE = OLED_W * PAGES;

uint8_t s_fb[FB_SIZE];
uint8_t s_sent[FB_SIZE];
bool s_sent_valid = false;
uint8_t s_brightness = 0xFF;

void command(const uint8_t *cmds, size_t n)
{
    Wire.beginTransmission(I2C_ADDR_OLED);
    Wire.write(0x00);   // control byte: a run of commands
    Wire.write(cmds, n);
    Wire.endTransmission();
}

void command1(uint8_t c) { command(&c, 1); }
}  // namespace

void oled_init()
{
    Wire.begin(PIN_I2C_SDA, PIN_I2C_SCL, 400000);

    const uint8_t init[] = {
        0xAE,                     // display off
        0xD5, 0x80,               // clock divide / oscillator
        0xA8, OLED_H - 1,         // multiplex: 32 rows
        0xD3, 0x00,               // no vertical offset
        0x40,                     // RAM start line 0
        0x8D, 0x14,               // charge pump on
        0x20, 0x00,               // horizontal addressing
#if OLED_ROTATE_180
        0xA0, 0xC0,               // columns and rows in RAM order
#else
        0xA1, 0xC8,               // columns and rows mirrored
#endif
        0xDA, OLED_COM_PINS,      // COM pin layout
        0x81, s_brightness,       // contrast
        0xD9, 0xF1,               // pre-charge
        0xDB, 0x40,               // VCOMH deselect level
        0xA4,                     // show RAM
        0xA6,                     // not inverted
    };
    command(init, sizeof(init));

    oled_clear();
    s_sent_valid = false;
    oled_flush();   // clear the RAM before the panel lights, so no noise flashes up
    command1(0xAF);
}

void oled_clear()
{
    memset(s_fb, 0, sizeof(s_fb));
}

void oled_pixel(int x, int y, bool on)
{
    if (x < 0 || x >= OLED_W || y < 0 || y >= OLED_H) return;
    uint8_t &b = s_fb[(y / 8) * OLED_W + x];
    const uint8_t m = 1u << (y % 8);
    if (on) b |= m;
    else b &= ~m;
}

void oled_fill_rect(int x, int y, int w, int h, bool on)
{
    for (int j = y; j < y + h; j++) {
        for (int i = x; i < x + w; i++) oled_pixel(i, j, on);
    }
}

void oled_flush()
{
    if (s_sent_valid && memcmp(s_fb, s_sent, FB_SIZE) == 0) return;

    // The 64 visible columns sit at OLED_COL_OFFSET in the controller's 128-column RAM.
    const uint8_t window[] = {
        0x21, OLED_COL_OFFSET, OLED_COL_OFFSET + OLED_W - 1,   // columns
        0x22, 0, PAGES - 1,                                    // pages
    };
    command(window, sizeof(window));

    // The Wire buffer holds 128 bytes; send the data in runs well under that.
    constexpr size_t CHUNK = 32;
    for (size_t i = 0; i < FB_SIZE; i += CHUNK) {
        Wire.beginTransmission(I2C_ADDR_OLED);
        Wire.write(0x40);   // control byte: a run of data
        Wire.write(s_fb + i, CHUNK);
        Wire.endTransmission();
    }
    memcpy(s_sent, s_fb, FB_SIZE);
    s_sent_valid = true;
}

void oled_set_brightness(uint8_t level)
{
    if (level == s_brightness) return;
    s_brightness = level;
    const uint8_t c[] = {0x81, level};
    command(c, sizeof(c));
}

void oled_power_off()
{
    const uint8_t off[] = {0xAE, 0x8D, 0x10};   // display off, charge pump off
    command(off, sizeof(off));
}
