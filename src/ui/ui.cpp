/*
 * The whole UI: one number on a 64x32 OLED, a scroll wheel and a button.
 *
 *   CONNECT?     in tiny letters: no Voltra (press the button to pair with the nearest one)
 *   SEARCHING    in tiny letters, dots filling in below: looking for / connecting to the Voltra
 *   120 hatched  the weight, unloaded (the digits cross-hatched)
 *   120 solid    loaded; during a set with an accessory on, the live resistance
 *   120 blinking auto load: waiting for the cable pull (slow), counting down (fast)
 *   OFF          the button is being held to power off: cross-hatched, filling in solid
 *                from the left to reach the right edge at 5 s
 *
 * Double-clicking the button (not while loaded) opens the Voltra picker: the end of each
 * Voltra's name in smaller letters, nearest first, with dots for its place in the list and
 * signal bars. The wheel moves through the list, a click connects to the one shown, and a
 * hold (or half a minute untouched) backs out. The Voltra already in use is underlined.
 */
#include "ui.h"

#include <Arduino.h>
#include <ctype.h>
#include <stdio.h>
#include <string.h>

#include <algorithm>
#include <string>
#include <vector>

#include "board_pins.h"
#include "hw/button.h"
#include "hw/knob.h"
#include "hw/oled.h"
#include "hw/power.h"
#include "ui/font_digits.h"
#include "ui/font_small.h"
#include "ui/font_tiny.h"
#include "ui/knob_step.h"
#include "voltra/voltra_client.h"

using voltra::ConnState;
using voltra::DeviceState;
using voltra::FoundDevice;
using VClient = voltra::Client;
using knobstep::apply_step;

namespace {

constexpr uint32_t SEND_DEBOUNCE_MS = 150;
constexpr uint32_t EDIT_HOLD_MS = 900;           // device values are not adopted while dialling
constexpr uint32_t TOGGLE_PENDING_MS = 5000;
constexpr uint32_t AUTO_LOAD_PENDING_MS = 4000;
constexpr uint32_t PAIR_LISTEN_MS = 3000;        // scan this long before picking the nearest
constexpr uint32_t PAIR_GIVE_UP_MS = 20000;      // none found by then: stop scanning
constexpr uint32_t PICK_TIMEOUT_MS = 30000;      // the picker backs out when left alone
constexpr size_t PICK_MAX = 8;                   // as many dots as fit beside the signal bars

// Panel contrast for each state. Loaded and unloaded differ by fill, not contrast.
constexpr uint8_t BRIGHT_LOADED = 0xFF;
constexpr uint8_t BRIGHT_PENDING = 0x60;
constexpr uint8_t BRIGHT_STATUS = 0x40;
constexpr uint8_t BRIGHT_PICK = 0x80;

constexpr int GLYPH_GAP = 2;
constexpr int SMALL_GAP = 1;
constexpr int TINY_GAP = 1;
constexpr int SEARCH_TEXT_Y = 9;    // "SEARCHING" in the tiny font...
constexpr int SEARCH_DOTS_Y = 21;   // ...and its dots below, filling in one by one
constexpr uint32_t SEARCH_DOT_MS = 400;

struct PickEntry {
    FoundDevice dev;
    bool heard = false;   // seen in this scan (the connected Voltra stops advertising)
};

struct Ui {
    int weight = 45;
    bool w_dirty = false;
    uint32_t w_changed = 0;
    uint32_t editing_until = 0;
    uint32_t toggle_pending_until = 0;
    bool toggle_target_loaded = false;
    // Auto load was just requested: show it until the Voltra reports its own progress.
    uint32_t auto_load_pending_until = 0;
    // A set is under way: loaded and the cable has moved since the last rest.
    bool set_active = false;
    // Pairing: scanning, then connecting to the strongest Voltra heard.
    bool pairing = false;
    uint32_t pair_started = 0;
    // Picker: the Voltras heard, the one shown, and what to go back to on backing out.
    bool picking = false;
    uint32_t pick_started = 0;
    uint32_t pick_last_input = 0;
    uint32_t pick_devices_version = 0;
    std::vector<PickEntry> pick;
    size_t pick_sel = 0;
    bool pick_moved = false;     // the wheel has been turned: the order stops changing
    bool pick_resume = false;    // a reconnect was stopped to scan: restart it on backing out
    std::string pick_current;    // address of the remembered Voltra

    knobstep::RateTracker knob_rate;

    uint32_t last_state_version = 0xFFFFFFFF;
    DeviceState st;
} ui;

int clampi(int v, int lo, int hi) { return v < lo ? lo : (v > hi ? hi : v); }

/** Weight ceiling: the Voltra's own max-weight setting (230 lb until it is read). */
int weight_max()
{
    return ui.st.max_weight > voltra::MIN_TARGET_LB ? ui.st.max_weight : voltra::DEFAULT_MAX_TARGET_LB;
}

// ---------------------------------------------------------------------------
// Drawing
// ---------------------------------------------------------------------------
/*
 * Glyph fill: the unloaded weight is drawn as a diagonal cross-hatch, lines both ways
 * HATCH_PITCH px apart, anchored to the screen so it runs on unbroken from one digit to
 * the next. Columns left of g_solid_x are drawn solid instead, which is how OFF fills in.
 */
constexpr int HATCH_PITCH = 5;
int g_solid_x = OLED_W;

inline bool fill_lit(int x, int y)
{
    return x < g_solid_x || (x + y) % HATCH_PITCH == 0 || (x - y + OLED_H * HATCH_PITCH) % HATCH_PITCH == 0;
}

template <class G, size_t N>
const G *glyph(const G (&font)[N], char ch)
{
    for (const G &g : font) {
        if (g.ch == ch) return &g;
    }
    return nullptr;
}

template <class G>
void draw_glyph(const G &g, int x0, int y0)
{
    for (int y = 0; y < (int)(sizeof(g.rows) / sizeof(g.rows[0])); y++) {
        const uint32_t row = g.rows[y];
        for (int x = 0; x < g.w; x++) {
            if ((row >> x & 1) && fill_lit(x0 + x, y0 + y)) oled_pixel(x0 + x, y0 + y, true);
        }
    }
}

template <class G, size_t N>
int text_width(const G (&font)[N], const char *s, int gap)
{
    int w = 0;
    for (; *s; s++) {
        const G *g = glyph(font, *s);
        if (g) w += g->w + (w ? gap : 0);
    }
    return w;
}

/**
 * Draw `s` centred across the panel from row `y`; returns its left edge. With `only` >= 0,
 * just that character of it (the rest keep their place).
 */
template <class G, size_t N>
int draw_centred(const G (&font)[N], const char *s, int y, int gap, int only = -1)
{
    const int x0 = (OLED_W - text_width(font, s, gap)) / 2;
    int x = x0;
    for (int i = 0; s[i]; i++) {
        const G *g = glyph(font, s[i]);
        if (!g) continue;
        if (only < 0 || only == i) draw_glyph(*g, x, y);
        x += g->w + gap;
    }
    return x0;
}

/**
 * The big digits, centred. With `only` >= 0, just that character. `solid` from 0 (all
 * cross-hatched) to 1 (all solid): how far across, from the left, the text is filled in.
 */
void draw_text(const char *s, int only = -1, float solid = 1.0f)
{
    const int w = text_width(DIGIT_FONT, s, GLYPH_GAP);
    g_solid_x = (OLED_W - w) / 2 + (int)(w * solid + 0.5f);
    draw_centred(DIGIT_FONT, s, 0, GLYPH_GAP, only);
    g_solid_x = OLED_W;
}

// ---------------------------------------------------------------------------
// Sending edits to the device
// ---------------------------------------------------------------------------
void set_weight(int lb)
{
    const int v = clampi(lb, voltra::MIN_TARGET_LB, weight_max());
    if (v == ui.weight) return;
    ui.weight = v;
    const uint32_t now = millis();
    ui.w_dirty = true;
    ui.w_changed = now;
    ui.editing_until = now + EDIT_HOLD_MS;
}

void flush_pending(uint32_t now)
{
    if (ui.w_dirty && now - ui.w_changed >= SEND_DEBOUNCE_MS) {
        ui.w_dirty = false;
        if (ui.st.connected()) VClient::instance().setWeight(ui.weight);
    }
}

// ---------------------------------------------------------------------------
// Pairing: a click with no Voltra connected takes the nearest one (the strongest signal)
// after listening for a moment, and remembers it. The picker below chooses by hand.
// ---------------------------------------------------------------------------
void start_pairing()
{
    VClient &c = VClient::instance();
    c.disconnect();
    c.forgetSavedDevice();
    c.scanStart();
    ui.pairing = true;
    ui.pair_started = millis();
}

void poll_pairing(uint32_t now)
{
    if (!ui.pairing) return;
    VClient &c = VClient::instance();
    if (now - ui.pair_started < PAIR_LISTEN_MS) return;
    const std::vector<FoundDevice> devs = c.devices();
    const FoundDevice *best = nullptr;
    for (const FoundDevice &d : devs) {
        if (!best || d.rssi > best->rssi) best = &d;
    }
    if (best) {
        log_i("pairing with %s (rssi %d)", best->name.c_str(), best->rssi);
        c.scanStop();
        c.connectTo(*best);   // the client saves it once the handshake succeeds
        ui.pairing = false;
    } else if (now - ui.pair_started >= PAIR_GIVE_UP_MS) {
        c.scanStop();
        ui.pairing = false;
    }
}

// ---------------------------------------------------------------------------
// Picker: choose the Voltra by hand from those in range.
// ---------------------------------------------------------------------------
void open_picker()
{
    VClient &c = VClient::instance();
    const uint32_t now = millis();
    const FoundDevice saved = c.savedDevice();
    ui.pairing = false;
    ui.pick.clear();
    ui.pick_sel = 0;
    ui.pick_moved = false;
    ui.pick_current = saved.address;
    ui.pick_resume = false;
    if (ui.st.connected()) {
        // Stay connected while looking, so backing out changes nothing. The connected
        // Voltra stops advertising, so list it without having heard it.
        if (!saved.address.empty()) ui.pick.push_back({saved, false});
    } else {
        // Retrying the remembered Voltra would keep interrupting the scan.
        ui.pick_resume = !saved.address.empty() && ui.st.conn != ConnState::Idle;
        c.disconnect();
    }
    c.scanStart();
    ui.pick_devices_version = c.devicesVersion() - 1;
    ui.picking = true;
    ui.pick_started = now;
    ui.pick_last_input = now;
}

/** Back out: leave things as they were before the picker opened. */
void close_picker()
{
    VClient &c = VClient::instance();
    c.scanStop();
    if (ui.pick_resume) c.connectTo(c.savedDevice());
    ui.picking = false;
}

/** Connect to the Voltra shown. The client remembers it once the handshake succeeds. */
void choose_pick()
{
    if (ui.pick.empty()) return;   // nothing heard yet: keep looking
    VClient &c = VClient::instance();
    const PickEntry &e = ui.pick[ui.pick_sel];
    c.scanStop();
    if (!(e.dev.address == ui.pick_current && ui.st.connected())) {
        log_i("picked %s", e.dev.name.c_str());
        c.disconnect();
        c.connectTo(e.dev);
    }
    ui.picking = false;
}

void pick_turn(int delta)
{
    ui.pick_last_input = millis();
    if (ui.pick.empty()) return;
    const int n = (int)ui.pick.size();
    ui.pick_sel = (size_t)clampi((int)ui.pick_sel + (delta > 0 ? 1 : -1), 0, n - 1);
    ui.pick_moved = true;
}

/**
 * Take in what the scan has heard. Until the wheel is turned the list stays ordered with
 * the Voltra in use first and the rest nearest first, showing the nearest other one; after
 * that the order holds still and newcomers join the end.
 */
void poll_picker(uint32_t now)
{
    if (!ui.picking) return;
    if (now - ui.pick_last_input >= PICK_TIMEOUT_MS) {
        close_picker();
        return;
    }
    VClient &c = VClient::instance();
    if (c.devicesVersion() == ui.pick_devices_version) return;
    ui.pick_devices_version = c.devicesVersion();

    const std::string shown = ui.pick.empty() ? std::string() : ui.pick[ui.pick_sel].dev.address;
    for (const FoundDevice &d : c.devices()) {
        if ((int32_t)(d.last_seen_ms - ui.pick_started) < 0) continue;   // from an earlier scan
        auto it = std::find_if(ui.pick.begin(), ui.pick.end(),
                               [&](const PickEntry &e) { return e.dev.address == d.address; });
        if (it != ui.pick.end()) {
            it->dev.rssi = d.rssi;
            it->dev.name = d.name;
            it->heard = true;
        } else if (ui.pick.size() < PICK_MAX) {
            ui.pick.push_back({d, true});
        }
    }
    if (ui.pick.empty()) return;

    if (ui.pick_moved) {
        for (size_t i = 0; i < ui.pick.size(); i++) {
            if (ui.pick[i].dev.address == shown) ui.pick_sel = i;
        }
        return;
    }
    const std::string &cur = ui.pick_current;
    std::stable_sort(ui.pick.begin(), ui.pick.end(), [&](const PickEntry &a, const PickEntry &b) {
        const bool ac = a.dev.address == cur, bc = b.dev.address == cur;
        if (ac != bc) return ac;
        return a.heard && b.heard && a.dev.rssi > b.dev.rssi;
    });
    ui.pick_sel = (ui.pick.size() > 1 && ui.pick[0].dev.address == cur) ? 1 : 0;
}

/** The end of a Voltra's name that fits the panel, "VTR-" dropped, in capitals. */
std::string pick_label(const std::string &name)
{
    std::string s;
    const size_t prefix = strlen(voltra::DEVICE_NAME_PREFIX);
    const size_t skip = name.compare(0, prefix, voltra::DEVICE_NAME_PREFIX) == 0 ? prefix : 0;
    for (size_t i = skip; i < name.size(); i++) {
        const char ch = (char)toupper((unsigned char)name[i]);
        if (glyph(SMALL_FONT, ch)) s += ch;
    }
    size_t from = 0;
    while (from < s.size() && text_width(SMALL_FONT, s.c_str() + from, SMALL_GAP) > OLED_W) from++;
    return s.substr(from);
}

// ---------------------------------------------------------------------------
// Button
// ---------------------------------------------------------------------------
bool auto_loading(uint32_t now)
{
    // A press-to-load runs briefly through the auto-load states; that is not an auto load.
    const bool tap_loading = now < ui.toggle_pending_until && ui.toggle_target_loaded;
    return ui.st.connected() && !tap_loading &&
           (ui.st.auto_loading() || now < ui.auto_load_pending_until);
}

/** Press: load / unload. With no Voltra connected, pair with the nearest one. */
void on_button_click()
{
    VClient &c = VClient::instance();
    const uint32_t now = millis();
    if (ui.picking) {
        choose_pick();
        return;
    }
    if (!ui.st.connected()) {
        // Already pairing, or connecting to the Voltra it just picked: let that finish.
        if (!ui.pairing && ui.st.conn != ConnState::Connecting) start_pairing();
        return;
    }
    if (ui.st.conn != ConnState::Ready) return;
    // Push a pending wheel edit first so the device loads the weight on screen.
    flush_pending(now + SEND_DEBOUNCE_MS);
    if (!ui.st.loaded() && auto_loading(now)) {
        // Pressing during auto load cancels it.
        ui.auto_load_pending_until = 0;
        c.unload();
        return;
    }
    const bool loaded = ui.st.loaded();
    ui.toggle_target_loaded = !loaded;
    ui.toggle_pending_until = now + TOGGLE_PENDING_MS;
    // load() picks a plain load or, with the cable pulled out, a direct load.
    if (loaded) c.unload();
    else c.load();
}

/**
 * Hold the button about a second and let go: start the Voltra's auto load (loads once the
 * cable is pulled and held). Holding on past that runs the power-off countdown instead.
 */
void on_button_hold()
{
    if (ui.picking) {
        close_picker();
        return;
    }
    if (ui.st.conn != ConnState::Ready || ui.st.loaded() || ui.st.auto_loading()) return;
    flush_pending(millis() + SEND_DEBOUNCE_MS);
    ui.toggle_pending_until = 0;
    ui.auto_load_pending_until = millis() + AUTO_LOAD_PENDING_MS;
    VClient::instance().autoLoad();
}

/** Held through the countdown: let the Voltra go, then power off. Does not return. */
void on_power_off()
{
    // Disconnect cleanly so the Voltra sees the remote go at once rather than after a
    // link timeout. The saved Voltra is kept, so it reconnects after powering on.
    VClient &c = VClient::instance();
    if (ui.pairing || ui.picking) c.scanStop();
    if (c.state().conn != ConnState::Idle) {
        c.disconnect();
        for (int i = 0; i < 100 && c.state().conn != ConnState::Idle; i++) delay(10);
    }
    power_off();   // waits for the button to be let go; "OFF" stays up until then
}

/** Double click: open the picker. Loaded, it is just a click (the picker is not offered). */
void on_button_double_click()
{
    if (ui.picking || (ui.st.connected() && ui.st.loaded())) on_button_click();
    else open_picker();
}

// ---------------------------------------------------------------------------
// Following the Voltra
// ---------------------------------------------------------------------------
void adopt_state(uint32_t now)
{
    VClient &c = VClient::instance();
    if (c.version() == ui.last_state_version) return;
    ui.last_state_version = c.version();
    ui.st = c.state();

    // Adopt the device's weight unless the wheel is mid-edit.
    if (now >= ui.editing_until && ui.st.weight >= voltra::MIN_TARGET_LB && !ui.w_dirty) {
        ui.weight = ui.st.weight;
    }
    if (now < ui.toggle_pending_until && ui.st.loaded() == ui.toggle_target_loaded) {
        ui.toggle_pending_until = 0;   // confirmed
    }

    // A set is under way while the Voltra's workout status says so and the cable has
    // actually moved (the status turns "active" on loading, before any rep). It ends the
    // moment the status goes to resting or unloading.
    const bool moving = ui.st.rep_phase >= 1 && ui.st.rep_phase <= 3;
    const int ws = ui.st.workout_status;
    if (!ui.st.loaded()) {
        ui.set_active = false;
    } else if (ws >= 0) {
        if (ws != voltra::WORKOUT_STATUS_ACTIVE) ui.set_active = false;
        else if (moving) ui.set_active = true;
    } else {
        // no status seen yet: fall back to the mode, which covers the first set
        const int mode = ui.st.fitness_mode >= 0 ? (ui.st.fitness_mode & 0xFF) : -1;
        if (mode == voltra::FITNESS_MODE_STRENGTH_IDLE) ui.set_active = false;
        else if (moving) ui.set_active = true;
    }
}

// ---------------------------------------------------------------------------
// The picture
// ---------------------------------------------------------------------------
int signal_bars(int rssi)
{
    return rssi >= -60 ? 4 : rssi >= -70 ? 3 : rssi >= -80 ? 2 : 1;
}

/**
 *   3F2A          the end of the name, underlined when it is the Voltra in use
 *   o o * o  .ll  its place in the list, and signal bars (none for the connected one)
 */
void render_picker(uint32_t now)
{
    if (ui.pick.empty()) {
        draw_text("---", (now / 300) % 3);   // listening
        oled_set_brightness(BRIGHT_STATUS);
        oled_flush();
        return;
    }
    const PickEntry &e = ui.pick[ui.pick_sel];
    const std::string label = pick_label(e.dev.name);
    const int x0 = draw_centred(SMALL_FONT, label.c_str(), 0, SMALL_GAP);
    if (e.dev.address == ui.pick_current) {
        oled_fill_rect(x0, SMALL_FONT_H + 2, text_width(SMALL_FONT, label.c_str(), SMALL_GAP), 1, true);
    }

    for (size_t i = 0; i < ui.pick.size(); i++) {
        const int x = (int)i * 5, y = 25;
        oled_fill_rect(x, y, 3, 3, true);
        if (i != ui.pick_sel) oled_pixel(x + 1, y + 1, false);
    }
    if (e.heard) {
        const int bars = signal_bars(e.dev.rssi);
        for (int b = 0; b < 4; b++) {
            const int h = b < bars ? 3 * (b + 1) : 1;
            oled_fill_rect(OLED_W - 11 + 3 * b, OLED_H - h, 2, h, true);
        }
    }
    oled_set_brightness(BRIGHT_PICK);
    oled_flush();
}

void render(uint32_t now)
{
    const DeviceState &st = ui.st;
    oled_clear();

    const uint32_t held = button_held_ms();
    if (held >= BUTTON_CANCEL_MS) {
        // cross-hatched at first, filling in solid from the left to reach the right
        // edge at the power-off point
        const uint32_t span = POWER_OFF_HOLD_MS - BUTTON_CANCEL_MS;
        const uint32_t into = std::min(held - BUTTON_CANCEL_MS, span);
        draw_text("OFF", -1, (float)into / span);
        oled_set_brightness(BRIGHT_LOADED);
        oled_flush();
        return;
    }
    if (ui.picking) {
        render_picker(now);
        return;
    }

    // Until the Voltra has reported its weight there is no weight to show.
    const bool weight_known = st.conn == ConnState::Ready && st.weight >= voltra::MIN_TARGET_LB;
    if (!weight_known) {
        const bool busy = ui.pairing || st.conn != ConnState::Idle;
        if (busy) {
            draw_centred(TINY_FONT, "SEARCHING", SEARCH_TEXT_Y, TINY_GAP);
            const int dots = (now / SEARCH_DOT_MS) % 4;   // none, then 1, 2, 3
            for (int i = 0; i < dots; i++) {
                const int x = OLED_W / 2 - 6 + i * 5;
                for (int d = 0; d < 4; d++) oled_pixel(x + (d & 1), SEARCH_DOTS_Y + (d >> 1), true);
            }
        } else {
            draw_centred(TINY_FONT, "CONNECT?", (OLED_H - TINY_FONT_H) / 2, TINY_GAP);
        }
        oled_set_brightness(BRIGHT_STATUS);
        oled_flush();
        return;
    }

    const bool loaded = st.loaded();
    int shown = ui.weight;
    // With an accessory on, the resistance changes through the rep. During a set the
    // number follows it, as on the Voltra, while the cable is moving (between reps it goes
    // slack and the reading falls towards 0) and unless the wheel is being turned.
    const bool accessory_on = st.chains > 0 || st.chains_lb > 0 ||
                              st.eccentric != 0 || st.eccentric_lb != 0;
    const bool moving = st.rep_phase >= 1 && st.rep_phase <= 3;
    if (loaded && ui.set_active && accessory_on && moving && st.live_force_tenths >= 0 &&
        now >= ui.editing_until) {
        shown = (st.live_force_tenths + 5) / 10;
    }

    bool visible = true;
    if (!loaded && auto_loading(now)) {
        // Waiting for the cable pull blinks slowly; the 3 s countdown blinks fast.
        const uint32_t period = st.direct_load_countdown_ms > 0 ? 125 : 400;
        visible = (now / period) % 2 == 0;
    }

    if (visible) {
        char buf[8];
        snprintf(buf, sizeof(buf), "%d", shown);
        draw_text(buf, -1, loaded ? 1.0f : 0.0f);
    }

    const bool pending = now < ui.toggle_pending_until && loaded != ui.toggle_target_loaded;
    oled_set_brightness(pending ? BRIGHT_PENDING : BRIGHT_LOADED);
    oled_flush();
}

}  // namespace

void ui_init()
{
    ui.st = VClient::instance().state();
    render(millis());
}

void ui_poll()
{
    const uint32_t now = millis();

    const int delta = knob_take_delta();
    if (delta && ui.picking) {
        pick_turn(delta);
    } else if (delta) {
        const int step = ui.knob_rate.step(delta, now);
        if (ui.st.conn == ConnState::Ready && ui.st.weight >= voltra::MIN_TARGET_LB) {
            set_weight(apply_step(ui.weight, delta, step));
        }
    }

    switch (button_take_event()) {
        case ButtonEvent::Click: on_button_click(); break;
        case ButtonEvent::DoubleClick: on_button_double_click(); break;
        case ButtonEvent::Hold: on_button_hold(); break;
        case ButtonEvent::PowerOff: on_power_off(); break;
        case ButtonEvent::None: break;
    }

    flush_pending(now);
    adopt_state(now);
    poll_pairing(now);
    poll_picker(now);

    if (ui.auto_load_pending_until && (ui.st.auto_loading() || ui.st.loaded())) {
        ui.auto_load_pending_until = 0;   // the Voltra has taken over
    }
    if (ui.auto_load_pending_until && now >= ui.auto_load_pending_until) ui.auto_load_pending_until = 0;
    if (ui.toggle_pending_until && now >= ui.toggle_pending_until) ui.toggle_pending_until = 0;

    // A click waits to see if a second follows only where a double click means something:
    // never while loaded, so unloading stays immediate.
    button_set_double_click(!ui.picking && !(ui.st.connected() && ui.st.loaded()));

    render(now);
}
