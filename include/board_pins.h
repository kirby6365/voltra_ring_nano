#pragma once
// Seeed XIAO ESP32-C6 pin map for Voltra Ring Nano.
// D-pin names are the XIAO's silkscreen; the numbers are ESP32-C6 GPIOs.
// GPIO3 / GPIO14 drive the board's RF switch (set up by the Arduino variant) and GPIO15 is
// its user LED, so none of them are used here.

// 0.49" 64x32 OLED (SSD1306 / SSD1315) on I2C
#define PIN_I2C_SDA     22   // D4
#define PIN_I2C_SCL     23   // D5
#define I2C_ADDR_OLED   0x3C

// Panel geometry inside the controller's 128x64 RAM. 64x32 panels sit in the middle
// columns; OLED_COL_OFFSET / OLED_COM_PINS (platformio.ini) suit other glass.
#define OLED_W          64
#define OLED_H          32
#ifndef OLED_COL_OFFSET
#define OLED_COL_OFFSET 32
#endif
#ifndef OLED_COM_PINS
#define OLED_COM_PINS   0x12   // alternative COM pin layout, no left/right remap
#endif
#ifndef OLED_ROTATE_180
#define OLED_ROTATE_180 0
#endif

// Controls in the case's end bay, all switching to GND
#define PIN_ENC_A       2    // D2  scroll wheel encoder (quadrature, common to GND)
#define PIN_ENC_B       21   // D3
#define PIN_BUTTON      1    // D1  load / unload push button; an LP pad, so it wakes the
                             //     chip from deep sleep
