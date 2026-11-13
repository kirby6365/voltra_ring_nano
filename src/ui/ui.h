#pragma once

/** Show the first frame. Call once the client has begun. */
void ui_init();

/** Read the wheel and button, follow the Voltra, and redraw. Call every UI_POLL_MS. */
void ui_poll();

constexpr unsigned UI_POLL_MS = 25;
