// Case for Voltra Ring Nano: Seeed XIAO ESP32-C6 + 0.49" 64x32 OLED module + 601220 LiPo,
// with the scroll wheel (mouse wheel encoder) set into the far corner -- it sticks out of both
// the display face and the end face -- and a button on the end face beside it.
// Units: mm.  Model coordinates: Z = 0 is the display face, Z grows toward the back.
// The case is centred on X; the near end is at -Y, the controls end at +Y.
//
// Layout: the case is only as long as the display plus the controls, and the rest is stacked
// behind the display. From the display face back: the OLED module, face down behind the window;
// the LiPo, lying across the case behind it; then the XIAO, lying across the case on its back
// (USB-C, antenna and shield toward the lid), with its USB-C out of the -X side wall. The XIAO
// reaches over the wire gap and the top of the protoboard. The controls bay at the far end holds
// a strip of protoboard standing upright across the case, with the tact switch and the wheel
// encoder side by side on it; it slides into a groove in the -X side wall from the open back.
//
// The lid slides in from the near end: a tongue along each of its long edges runs in a groove in
// the side walls, and a sprung finger at its near end clicks a ridge into a notch in the end
// wall. It carries the same two magnets, at the same spacing, as the voltra_ring lid, so the
// voltra_ring clip and band plate fit it unchanged.
//
// Assembly:
//   1. Solder the wires to the OLED module's pin holes and lay it face down in its frame
//      behind the window.
//   2. Put the button into its hole from inside.
//   3. Build the protoboard (part="template") and slide it into its groove from the open back,
//      components facing the far end.
//   4. Push the wheel in through the corner opening from outside (diagonally), then push the
//      shaft in through the side hole. Turn the shaft until its thin tip drops into the encoder,
//      then turn the wheel until the shaft's thick hex drops into the wheel's snug hex, and push
//      it home.
//   5. Lay the battery flat on the OLED frame's side ribs, leads toward -X, and stick a 1 mm
//      foam pad on its back.
//   6. Wire the XIAO (wires from its castellated pads run down past the battery's ends and
//      through the wire gap), then lay it face up on its ledges, USB-C end first into the cutout.
//   7. Slide the lid in from the near end until the finger clicks. To open, lift the finger's end
//      with a fingernail and slide the lid out.
//
// Render a part with:  openscad -D 'part="tub"' -o tub.stl voltra_ring_nano_case.scad
// part = "tub" | "lid" | "wheel" | "shaft" | "button" | "fit_test" | "fit_tips" | "template" (2D)
//      | "clip_a" | "clip_b" | "liner_a" | "liner_b" | "band_20" | "band_13"
//      | "assembly" | "exploded" | "section" | "section_wheel" | "section_across"
//      | "mount" | "mount_band" | "print"

part = "assembly";

/* ---------------- XIAO ESP32-C6 (check yours) ---------------- */
xiao_w     = 17.8;   // along the case, Y (some listings say 17.5)
xiao_l     = 21.0;   // across the case, X; PCB only
xiao_pcb_t = 1.2;
xiao_top_h = 3.3;    // tallest part on the top side: the USB-C receptacle
usb_w      = 9.0;    // USB-C receptacle
usb_h      = 3.2;
usb_over   = 0.6;    // how far the receptacle sticks out past the PCB end

/* ---------------- 0.49" 64x32 OLED module (check yours) ---------------- */
// HiLetgo's 4-pin SSD1306 board (Amazon B0CDWXFCN2): 15 x 16 mm, its pins along the far edge.
// It reaches past the battery into the wire gap, beside the wheel.
oled_pcb_w   = 15.0;   // X (the panel's long side runs across the case)
oled_pcb_l   = 16.0;   // Y
oled_pcb_t   = 1.0;
oled_glass_t = 1.2;    // panel glass, on the front of the PCB
oled_back_h  = 1.6;    // parts and wire joints behind the PCB
oled_aa_w    = 11.18;  // active area
oled_aa_l    = 5.58;
oled_aa_dx   = 0;      // active area centre, from the PCB centre
oled_aa_dy   = 0.0;    // active area centred on the board: set against the window on a print
oled_tab_fit = 0.1;    // between the PCB's far edge and the frame's tab

/* ---------------- battery: 601220 LiPo with its protection board ---------------- */
bat_x = 22.0;   // across the case: the cell's 20 mm length plus the protection board
bat_y = 12.5;   // along the case: its 12 mm width
bat_h = 6.2;    // its 6 mm thickness

/* ---------------- case parameters ---------------- */
face_t     = 1.0;    // display face over the electronics
wall       = 1.6;    // side walls
wall_end   = 1.6;    // near end wall
edge_ch    = 0.6;    // outer edge chamfer
outer_r    = 3.5;    // outer corner radius at the near end (seen from above)
far_r      = 2.0;    // ...and at the controls end
fit        = 0.15;   // clearance round the XIAO and the OLED
bat_fit    = 0.3;    // clearance round the battery (per side)
bat_lift   = 0.2;    // between the OLED's back parts and the battery
xiao_gap   = 1.0;    // between the battery and the XIAO: its battery pads' wires, and a foam pad
lid_clear  = 0.5;    // between the XIAO's tallest part and the lid
ledge_w    = 0.8;    // how far the ledges reach under the XIAO
rib_t      = 0.6;    // OLED frame ribs
win_margin = 0.3;    // display window, round the active area
usb_cut_w  = 9.8;    // USB-C cutout in the -X wall (fits the plug shell and slim overmolds)
usb_cut_h  = 3.8;
usb_cut_r  = 1.0;

/* ---------------- controls bay ---------------- */
wire_gap   = 4.0;    // battery end to protoboard: solder joints and wires, and keeps the OLED's ribbon off the wheel
pb_t       = 1.6;    // protoboard thickness
pb_fit     = 0.3;    // groove clearance on the board thickness
groove_d   = 0.8;    // groove depth into the -X side wall
front_t    = 1.6;    // display-face plate over the bay
front_skin = 0.8;    // plate left over the encoder (it sits in a pocket in the plate)
end_t      = 2.0;    // far end wall
top_skin   = 0.4;    // wall left over the encoder where the rounded top edge passes it
top_enc_clear = 0.1; // ...plus this much space round the encoder body's corner

// mouse wheel encoder (MECCANIXITY "4.5 mm"); axis height + body sizes from the listing, check yours
enc_axis_h = 4.5;    // shaft-hole centre height above the protoboard
enc_t      = 4.2;    // body thickness along the shaft (measured)
enc_w      = 9.6;    // body width across the shaft (in the board plane)
enc_top    = 3.9;    // body extends this far past the axis, away from the board
// Small printed hexes come out off-size (keys fat, holes tight), so the two printed fits
// are set from test prints -- print part="fit_test" to pick them for your printer.
// A hex key only locks in a hex hole while the hole's across-flats is smaller than the
// key's across-corners (1.155 x its across-flats); past that it spins.
key_af     = 1.75;   // encoder centre hole: hex, across flats (measured)
key_print  = 1.80;   // shaft tip that goes into the encoder (confirmed by test print)
key_len    = 3.0;    // how far the tip goes into the encoder
drive_af   = 2.60;   // thicker hex section that drives the wheel (passes the side-wall hole)
drive_bore = 2.80;   // snug hex in the wheel that grips it (confirmed by test print)
drive_len  = 4.0;    // length of the snug hex, at the encoder end of the wheel
pass_d     = 3.4;    // rest of the wheel bore: round clearance, so the shaft slides through

wheel_d    = 14.1;   // as on voltra_ring
wheel_trim = 0.5;    // wheel made this much narrower on its encoder side (the encoder stood proud on a print)
rib_pitch  = 2.8;    // grip groove spacing round the rim
groove_w   = 1.6;    // groove width
groove_dp  = 1.0;    // groove depth
shaft_d    = 3.0;    // round bearing section of the shaft (in the side wall)
wheel_lid_clear = 0.3;   // between the wheel and a pocket in the lid over it (only cut when
lid_floor_min   = 0.5;   // the case is too shallow for the wheel), and the lid left over it

// 6x6x5 mm through-hole tact switch, beside the encoder
sw_body    = 6.0;
sw_body_h  = 3.5;
sw_h       = 5.0;    // to the top of the plunger
sw_plunger = 3.5;
// button bar on the end face, in front of the switch
btn_w      = 6.0;    // across the case
btn_hgt    = 5.0;
btn_proud  = 2.0;    // how far it stands out of the end face
btn_clear  = 0.35;   // clearance in its hole, per side
btn_ch     = 0.6;    // chamfer round the pressing face
btn_lip    = 1.2;    // retaining wings above and below the bar, inside the end wall
btn_lip_t  = 1.2;
btn_pin_w  = 3.0;    // plunger pin from the bar back to the switch: its height (Z)

/* ---------------- sliding lid ---------------- */
lid_t      = 2.0;    // keep at 2.0: sets how far the magnets stand out (as on voltra_ring)
lid_gap    = 0.15;   // side clearance round the lid plate
tongue_w   = 0.6;    // tongues along the lid's long edges, into the side walls
tongue_z0  = 0.5;    // tongue, from the lid's inner face
tongue_z1  = 1.5;
tongue_fit = 0.12;   // groove clearance round the tongue
finger_w   = 5.0;    // sprung finger at the lid's near end, off to the +X side of the magnets
finger_l   = 6.5;
finger_t   = 1.2;    // thinned from inside so it flexes
slot_w     = 0.6;    // slot cut round the finger
ridge_h    = 0.3;    // how far the finger's ridge drops into the end wall's notch
ridge_w    = 4.0;    // ridge length (across the case)

/* ---------------- mounts: magnets in the lid + magnetic accessories ---------------- */
// Two 6 x 3 mm round magnets are glued into shallow pockets in the lid's outer face, on its
// centreline, and stand proud of it. Each accessory (the spring clip, the strap plate) has two
// matching holes with its own magnets glued at the bottom: the lid's magnets slide into the
// holes and meet the accessory's face to face, so they also locate it. Each hole is stepped: a
// snug seat for the accessory's magnet, then a looser, chamfered bore for the lid's magnet to
// slide into. Set the lid's two with opposite poles out (N, S); stick each accessory magnet onto
// a lid magnet to mark its face, then glue it in with that marked face up, so both pairs attract
// (and the accessory only goes on one way round).
mag_d      = 6;      // round magnets: 6 mm dia x 3 mm
mag_t      = 3;
mag_fit    = 0.1;    // accessory magnet seat clearance, on the radius
mag_lid_fit = 0.3;   // lid magnet pocket clearance, on the radius
mag_slide  = 0.3;    // accessory bore clearance round the lid's magnets, on the radius
mag_lead   = 0.5;    // chamfer on the mouth of that bore
mag_floor  = 0.4;    // lid left behind its magnets
mag_dy     = 8.0;    // magnets at +/- mag_dy along the device, about mount_yc
acc_floor  = 0.6;    // accessory plastic behind its magnets

// spring clip: grips a handle running across the device. An upper jaw (magnets on top, a saddle
// round the top of the handle) and a lower C jaw pivot on a pin; a compression spring between
// their tails holds them shut -- squeeze the tails together to open it. Both jaws are lined with
// ribbed TPU liners, printed separately, that slide into dovetail grooves from the +X side up to
// a stop at the -X side. Identical to voltra_ring's.
//   Spring: 23/64" x 1-3/8" compression spring (9.1 mm OD x 34.9 mm long).
//   Pivot pin: M2x20 screw + nut, a 2 mm pin, or a length of 1.75 mm filament.
handle_d   = 30;     // handle the clip grips
clip_w     = 22;     // clip width, along the handle (across the device)
clip_dy    = 2.0;    // where the handle sits along the device, from the magnets' centre
ja_t       = 7.5;    // upper jaw thickness, along its tail and round the pivot
ja_seat    = 5.5;    // upper jaw thickness over the top of its saddle
sa_m       = 35;     // saddle spans this far round from the top of the handle, towards the mouth...
sa_p       = 40;     // ...and towards the pivot
sa_wall    = 3.0;    // saddle wall, beyond the liner
ja_u0      = -16;    // upper jaw's mouth-side end, from the handle centre
jaw_wall   = 4.0;    // lower (C) jaw thickness, beyond the liner
piv_u      = 16.5;   // pivot, along the device from the handle centre
piv_r      = 3.2;    // lower jaw knuckle radius
knuckle_w  = 10.6;   // lower jaw knuckle width, between the upper jaw's lugs
pin_d      = 2.2;    // pivot hole
tail_u1    = 32;     // both tails end here (along the device, from the handle centre)
spring_od  = 9.53;   // 3/8"
spring_len = 15.88;  // 5/8" free length
spring_pre = 3.4;    // compressed this much with the clip shut
pocket_a   = 3.0;    // spring pocket depth in the upper jaw's tail
pocket_b   = 4.0;    // ...and in the lower jaw's tail
// TPU grip liners
tpu_base   = 1.6;    // liner thickness behind the ribs
grip_h     = 0.5;    // grip ribs along the handle, standing this far off the liner
grip_pitch = 3.0;    // grip rib spacing round the handle
dv_n       = 3.0;    // dovetail keys on the liners' backs: neck width...
dv_w       = 4.6;    // ...head width...
dv_h       = 1.4;    // ...and depth
dv_fit     = 0.15;   // groove clearance, per face
dv_stop    = 1.5;    // grooves stop this far short of the jaws' -X side
kb_a       = [20, 100];   // lower jaw key angles (the upper jaw's sits between its magnets)

// strap plate: magnets on top, a sideways tunnel underneath for an elastic strap
strap_w    = 20.0;   // elastic strap width
strap_w_narrow = 13.0;   // ...for part="band_13": a 1/2" (12.7 mm) strap
strap_t    = 2.6;    // tunnel height
band_w     = 26;     // plate width (across the device)
band_len   = 27;     // plate length, along the device (centred on the magnets)
band_bot   = 1.6;    // floor under the tunnel

$fn = 64;

/* ---------------- derived: main cavity ---------------- */
z_front  = 0;
cav_w    = max(bat_x + 2*bat_fit, xiao_l + 0.4 + fit, oled_pcb_w + 2*fit + 2*rib_t);
outer_w  = cav_w + 2*wall;
cav_r    = 0.6;                                 // inner corners: tight, so the XIAO and battery reach into them

cav_y0   = 0;                                   // near end wall's inner face
near_y   = -wall_end;                           // outer near end face
oled_y0  = cav_y0 + fit;                        // OLED PCB
oled_y1  = oled_y0 + oled_pcb_l;
oled_yc  = (oled_y0 + oled_y1)/2;
bat_y0   = cav_y0 + ledge_w + bat_fit;          // clear of the XIAO's ledge on the end wall
bat_y1   = bat_y0 + bat_y;
cav_y1   = bat_y1 + bat_fit;                    // the OLED reaches on into the wire gap
// XIAO, across the case, USB-C end at -X (its receptacle sticks out into the side wall)
xiao_x0  = -cav_w/2 + 0.2;
xiao_x1  = xiao_x0 + xiao_l;
xiao_y0  = cav_y0 + 0.2;
xiao_y1  = xiao_y0 + xiao_w;
xiao_yc  = (xiao_y0 + xiao_y1)/2;

// the stack, front to back
oled_z1  = face_t + oled_glass_t + oled_pcb_t;   // OLED PCB, back face
bat_z0   = oled_z1 + oled_back_h + bat_lift;    // the battery rests on the OLED frame's side ribs
bat_z1   = bat_z0 + bat_h;
xiao_z0  = bat_z1 + xiao_gap;                   // XIAO PCB, underside (sits on the ledges)
xiao_z1  = xiao_z0 + xiao_pcb_t;
xiao_top = xiao_z1 + xiao_top_h;
usb_zc   = xiao_z1 + usb_h/2;

/* ---------------- derived: controls bay ---------------- */
wheel_r  = wheel_d/2;
wr_clear = wheel_r + 0.4;
wheel_z  = front_skin + 0.3 + enc_w/2;          // as close to the face as the encoder allows
pb_y0    = cav_y1 + wire_gap;                   // protoboard back face
pb_y1    = pb_y0 + pb_t;                        // protoboard component face
wheel_y  = pb_y1 + enc_axis_h;
end_y1   = wheel_y + wheel_z;                   // outer end face: as far from the axis as the display face
end_y0   = end_y1 - end_t;                      // inner end face

// tub depth: the stack, or the wheel (which would run into a pocket in the lid), whichever is deeper
z_back   = max(xiao_top + lid_clear, wheel_z + wheel_r + wheel_lid_clear + lid_floor_min - lid_t);
z_lid1   = z_back + lid_t;
lid_pocket = wheel_z + wheel_r + wheel_lid_clear > z_back;   // the wheel reaches into the lid

// across the bay, from -X: switch, encoder, wheel (its shaft bears in the +X wall)
sw_xc    = -cav_w/2 + 0.3 + sw_body/2;
enc_x0   = sw_xc + sw_body/2 + 0.4;
enc_x1   = enc_x0 + enc_t;                      // encoder's wheel-side face
wheel_x0 = enc_x1 + 0.5;
wheel_x1 = cav_w/2 - 0.4;
wheel_ribs = round(PI * wheel_d / rib_pitch);
wheel_proud     = wheel_r - wheel_z;             // past the display face
wheel_proud_end = wheel_r - (end_y1 - wheel_y);  // past the end face
btn_zc   = wheel_z;                             // the button sits level with the wheel's axis

// rounded top edge at the far end (display face into end face), following the wheel. Its
// radius is the largest that leaves top_skin of wall + top_enc_clear of space over the
// encoder body's corner, which sits ce in from the end face and cf in from the display face.
ce       = end_y1 - (wheel_y + enc_top);
cf       = wheel_z - enc_w/2 - z_front;
tr_s     = top_skin + top_enc_clear;
tr_k     = ce + cf - tr_s;
top_r    = floor((tr_k + sqrt(tr_k*tr_k - (ce*ce + cf*cf - tr_s*tr_s))) * 10) / 10;
slot_hl  = sqrt(wr_clear*wr_clear - pow(wheel_z - front_t, 2));             // face opening, behind the axis
end_open_z = wheel_z + sqrt(wr_clear*wr_clear - pow(end_y0 - wheel_y, 2));  // end opening depth
lid_pocket_hl = lid_pocket ? sqrt(pow(wheel_r + wheel_lid_clear, 2) - pow(z_back - wheel_z, 2)) : 0;   // behind the axis
// how far the wheel reaches toward the near end at the XIAO's underside
wheel_reach_y = xiao_z0 - wheel_z < wr_clear ? wheel_y - sqrt(wr_clear*wr_clear - pow(xiao_z0 - wheel_z, 2)) : 1e9;

pin_y0   = pb_y1 + sw_h + 0.1;                  // pin tip, just off the plunger
pin_len  = end_y0 - btn_lip_t - pin_y0;

pb_x0    = -cav_w/2 - groove_d + 0.1;           // protoboard: from in the -X groove...
pb_x1    = wheel_x0 - 0.4;                      // ...to just short of the wheel
pb_z0    = front_t;
pb_z1    = xiao_z0 - 0.3;                       // the XIAO lies over its top edge

shaft_len = outer_w/2 - (enc_x1 - key_len);

/* ---------------- derived: lid and mounts ---------------- */
lid_hw   = cav_w/2;                             // lid plate half-width, between the side walls
lid_y1   = end_y0 - 0.1;
mount_yc = (near_y + lid_y1)/2;                 // magnets centred on the lid
finger_x = mag_d/2 + 1.0 + slot_w + finger_w/2;   // finger centre, beside the magnets (fixed: the tub's notch is here)
clip_yc  = mount_yc + clip_dy;
mag_xy   = [for (sy=[-1,1]) [0, mount_yc + sy*mag_dy]];   // magnet centres
mag_proud = mag_t - (lid_t - mag_floor);      // how far the lid's magnets stand out of it
acc_slide = mag_proud + 0.2;                 // depth of the looser bore the lid's magnets slide into
acc_hole = acc_slide + mag_t;                // hole depth in the accessories (their magnet at the bottom)
band_top = acc_hole + acc_floor;             // strap plate: magnet layer above the tunnel
band_y0  = mount_yc - band_len/2;
band_y1  = mount_yc + band_len/2;
hr       = handle_d/2;
ja_top   = 0;
ja_bot   = ja_t;
piv_w    = ja_bot - 2.5;
seat_r   = hr + grip_h + tpu_base;
hc_w     = ja_seat + seat_r;
ka_a     = -90 + asin((mount_yc - clip_yc)/seat_r);
c_a0     = -35;  c_a1 = 135;
spring_u = (piv_u + piv_r + 1 + tail_u1) / 2;
spring_il = spring_len - spring_pre;
tb_top   = ja_bot + spring_il - pocket_a - pocket_b;
tb_bot   = tb_top + pocket_b + 2;
band_th  = band_top + strap_t + band_bot;

/* ---------------- checks ---------------- */
assert(xiao_y1 + 0.3 <= wheel_reach_y, "XIAO runs into the wheel: deepen the stack or shorten the XIAO's reach");
assert(pb_z1 >= wheel_z + enc_w/2 + 0.5, "protoboard too short for the encoder under the XIAO");
assert(usb_zc + usb_cut_h/2 + 0.5 <= z_back + tongue_z0 - tongue_fit, "USB-C cutout runs into the lid groove");
assert(wheel_x1 - wheel_x0 >= 6, "wheel too narrow: widen the case or move the switch");
assert(z_lid1 - (wheel_z + wheel_r + wheel_lid_clear) >= lid_floor_min - 1e-6, "lid too thin over the wheel");
assert(finger_x + finger_w/2 + slot_w <= lid_hw - 0.8, "no room for the lid's finger beside the magnets");
assert(finger_x - finger_w/2 - slot_w - (mag_d/2 + mag_lid_fit) >= 0.6, "lid magnet pockets run into the finger's slot");
assert(btn_zc + btn_hgt/2 + btn_lip <= z_back - 0.5, "button wings run into the lid");
assert(btn_zc - btn_hgt/2 - btn_lip >= front_t, "button wings run into the face plate");
assert(pin_len > 0.3, "no room for the button's plunger pin");
// the panel's ribbon bends round the PCB's far edge: it touched the wheel with 0.2 mm here
assert(norm([wheel_y - (oled_y1 + oled_tab_fit), wheel_z - oled_z1]) >= wheel_r + 1.1,
       "the OLED's far edge (and its ribbon) runs into the wheel");
assert(oled_y1 + oled_tab_fit + 0.4 <= pb_y0 - 0.2, "no room for the OLED's tab in front of the protoboard");
assert(mag_proud >= 0, "lid thicker than the magnets: use flush pockets instead");
assert(min([for (m=mag_xy) m[1]]) - mag_d/2 - mag_lid_fit >= near_y + 1.5, "magnets too near the lid's end");
assert(!lid_pocket || max([for (m=mag_xy) m[1]]) + mag_d/2 + mag_lid_fit + 0.8 < wheel_y - lid_pocket_hl,
       "magnets run into the lid's wheel pocket");
assert(piv_w - piv_r - 0.3 >= ja_top + 1.4, "upper jaw too thin over the pivot");
assert(mag_dy - (mag_d/2 + mag_slide + mag_lead) - (dv_w/2 + dv_fit) >= 1.0, "upper liner groove runs into the magnet holes");

echo(str("Outer size: ", outer_w, " x ", end_y1 - near_y, " x ", z_lid1 - z_front, " mm; far top edge R", top_r));
echo(str("Wheel: ", wheel_d, " dia x ", wheel_x1 - wheel_x0 - wheel_trim, " wide, sticks out ", wheel_proud,
         " (face) / ", wheel_proud_end, " (end); shaft ", shaft_len, " long",
         lid_pocket ? str("; lid over it ", z_lid1 - (wheel_z + wheel_r + wheel_lid_clear)) : ""));
echo(str("Protoboard: ", pb_x1 - pb_x0, " x ", pb_z1 - pb_z0, " mm"));
echo(str("Stack: OLED to ", oled_z1 + oled_back_h, ", battery ", bat_z0, "-", bat_z1, ", XIAO ", xiao_z0, "-", xiao_top,
         ", lid ", z_back, "-", z_lid1, "; XIAO clears the wheel by ", wheel_reach_y - xiao_y1));

/* ---------------- helpers ---------------- */
module rrect2d(w, l, r) offset(r) square([w-2*r, l-2*r], center=true);
module rrect(w, l, r, z0, z1) translate([0,0,z0]) linear_extrude(z1-z0) rrect2d(w, l, r);
module hex2d(af) circle(d=af/cos(30), $fn=6);   // flats parallel to X

// outer footprint: outer_r at the near end, far_r at the controls end
module outline2d(inset=0) hull() for (sx=[-1,1]) {
    translate([sx*(outer_w/2 - outer_r), near_y + outer_r]) circle(r=outer_r - inset);
    translate([sx*(outer_w/2 - far_r), end_y1 - far_r]) circle(r=far_r - inset);
}
module outline(inset, z0, z1) translate([0,0,z0]) linear_extrude(z1-z0) outline2d(inset);

// footprint block with chamfered front and back edges
module chamfered_block(z0, z1, c0=edge_ch, c1=edge_ch) hull() {
    outline(c0, z0, z0+0.01);
    outline(0, z0+c0, z1-c1);
    outline(c1, z1-0.01, z1);
}

// cylinder along +X
module xcyl(d, x0, x1) translate([x0,0,0]) rotate([0,90,0]) cylinder(d=d, h=x1-x0);
// hex prism along +X, flats facing +/-Z
module xhex(af, x0, x1) translate([x0,0,0]) rotate([0,90,0]) linear_extrude(x1-x0) rotate(90) hex2d(af);

/* ---------------- tub ---------------- */
// the material taken off by the far top round-over, grown inward by `inset`
module top_round(inset=0) translate([0, end_y1 - top_r, z_front + top_r]) difference() {
    translate([-outer_w, 0, -top_r - 1]) cube([2*outer_w, top_r + 1, top_r + 1]);
    xcyl(2*(top_r - inset), -outer_w, outer_w);
}

// a ledge standing out of a wall, its top at ztop, with a 45 degree underside so it prints:
// [x0, x1] x [y0, y1] is its top; `wall` names the side it grows from ("-y", "-x" or "+x")
module ledge(x0, x1, y0, y1, ztop, wall) {
    d = wall == "-y" ? y1 - y0 : x1 - x0;
    hull() {
        translate([x0, y0, ztop - 0.4]) cube([x1 - x0, y1 - y0, 0.4]);
        if (wall == "-y") translate([x0, y0, ztop - 0.4 - d]) cube([x1 - x0, 0.01, 0.01]);
        else if (wall == "-x") translate([x0, y0, ztop - 0.4 - d]) cube([0.01, y1 - y0, 0.01]);
        else translate([x1 - 0.01, y0, ztop - 0.4 - d]) cube([0.01, y1 - y0, 0.01]);
    }
}

// XIAO supports: a ledge along the near end wall under its near edge, and ledges on both side
// walls under its ends, beyond the battery so the battery still drops in past them. A lip
// beside its +X end locates it across (the USB-C in its cutout locates the other end).
module xiao_supports() {
    ys0 = cav_y1 + 0.1;
    ys1 = min(xiao_y1, pb_y0 - pb_fit/2 - 0.3);
    ledge(xiao_x0 + 1, xiao_x1 - 1, cav_y0 - 0.01, cav_y0 + ledge_w, xiao_z0, "-y");
    ledge(-cav_w/2 - 0.01, xiao_x0 + ledge_w, ys0, ys1, xiao_z0, "-x");
    ledge(xiao_x1 - ledge_w, cav_w/2 + 0.01, ys0, ys1, xiao_z0, "+x");
    translate([xiao_x1 + fit, ys0, xiao_z0 - 0.01]) cube([cav_w/2 - xiao_x1 - fit + 0.01, ys1 - ys0, xiao_z1 - xiao_z0]);
}

// OLED frame: ribs either side of its PCB, standing on to carry the battery, cut back clear of
// the wheel, and a tab at the -X end of its far edge, in front of the protoboard (at +X the wheel
// leaves no room for one). The end wall stops its near edge.
module oled_frame() {
    fw = oled_pcb_w + 2*fit;
    h  = oled_glass_t + oled_pcb_t;
    tab_y0 = oled_y1 + oled_tab_fit;
    difference() {
        union() {
            for (m=[0,1]) mirror([m,0,0])
                translate([fw/2, cav_y0 - 0.01, face_t - 0.01]) cube([rib_t, tab_y0 - cav_y0 + 0.01, bat_z0 - face_t + 0.01]);
            // reaches 1.2 mm in over the PCB, short of the switch's pins on the protoboard
            translate([-fw/2 - rib_t, tab_y0, face_t - 0.01]) cube([rib_t + fit + 1.2, pb_y0 - 0.2 - tab_y0, h]);
        }
        translate([0, wheel_y, wheel_z]) xcyl(2*wr_clear, wheel_x0 - 0.4, cav_w/2 + 1);
    }
}

module tub() {
    difference() {
        union() {
            difference() {
                chamfered_block(z_front, z_lid1, edge_ch, 0.3);
                // main cavity and wire gap, from behind the display face
                translate([0, (cav_y0 + pb_y0)/2, 0]) rrect(cav_w, pb_y0 - cav_y0, cav_r, face_t, z_lid1 + 1);
                // controls bay
                translate([-cav_w/2, pb_y0 - 1, front_t]) cube([cav_w, end_y0 - pb_y0 + 1, z_lid1]);
            }
            xiao_supports();
            oled_frame();
        }

        // lid slot: the plate between the side walls and the tongue grooves, open at the near end
        translate([-lid_hw - lid_gap, near_y - 5, z_back]) cube([2*(lid_hw + lid_gap), end_y0 - near_y + 5, lid_t + 1]);
        translate([-lid_hw - tongue_w - tongue_fit, near_y - 5, z_back + tongue_z0 - tongue_fit])
            cube([2*(lid_hw + tongue_w + tongue_fit), end_y0 - near_y + 5, tongue_z1 - tongue_z0 + 2*tongue_fit]);
        // notch on top of the near end wall for the finger's ridge
        translate([finger_x, near_y + wall_end/2, z_back]) ridge(ridge_w + 0.6, ridge_h + 0.05, 0.1);
        // lead-in for the ridge along the end wall's outer top edge
        translate([finger_x - (ridge_w + 0.6)/2, near_y, z_back]) rotate([-45,0,0]) translate([0, -0.5, -0.5]) cube([ridge_w + 0.6, 1, 1]);

        // USB-C cutout in the -X side wall
        translate([-outer_w/2 - 1, xiao_yc, usb_zc]) rotate([0, 90, 0])
            linear_extrude(wall + 2) rrect2d(usb_cut_h, usb_cut_w, usb_cut_r);

        // display window over the active area, flared toward the face
        translate([oled_aa_dx, oled_yc + oled_aa_dy, 0]) hull() {
            rrect(oled_aa_w + 2*win_margin, oled_aa_l + 2*win_margin, 0.5, face_t - 0.01, face_t + 0.01);
            rrect(oled_aa_w + 2*win_margin + 2*face_t, oled_aa_l + 2*win_margin + 2*face_t, 0.5 + face_t, -0.01, 0);
        }

        // protoboard groove in the -X wall
        translate([-cav_w/2 - groove_d, pb_y0 - pb_fit/2, front_t]) cube([groove_d + 0.02, pb_t + pb_fit, z_back + 1 - front_t]);

        // round over the far top edge (display face into end face); the lid side stays square
        top_round(0);

        // corner opening for the wheel: through the display face and down the end wall.
        // Square corners -- the wheel's rims run within 0.4 mm of the sides.
        translate([(wheel_x0 + wheel_x1)/2, 0, 0]) {
            open_w = wheel_x1 - wheel_x0 + 0.8;
            y0 = wheel_y - slot_hl;  y1 = end_y1 + 4;
            translate([0, (y0 + y1)/2, z_front - 1])
                linear_extrude(front_t + 1.02 - z_front) square([open_w, y1 - y0], center=true);
            translate([0, end_y0 - 0.01, (z_front - 4 + end_open_z)/2]) rotate([-90,0,0])
                linear_extrude(end_t + 1) square([open_w, end_open_z - (z_front - 4)], center=true);
        }

        // pocket for the encoder body under the face plate (leaves front_skin), continuing as a
        // shallow channel in the end wall that is open to the back, so it slides in with the board
        // (trimmed back to stay top_skin inside the rounded top edge)
        difference() {
            translate([enc_x0 - 0.3, pb_y1 - 0.01, front_skin])
                cube([enc_t + 0.6, wheel_y + enc_top + 0.3 - pb_y1, z_back]);
            top_round(top_skin);
        }

        // button hole in the end face, in front of the switch
        translate([sw_xc, end_y0 - 1, btn_zc]) rotate([-90,0,0])
            linear_extrude(end_t + 2) rrect2d(btn_w + 2*btn_clear, btn_hgt + 2*btn_clear, 1.0);

        // wheel shaft: bearing hole + counterbore for the head, in the +X side wall
        translate([0, wheel_y, wheel_z]) {
            xcyl(shaft_d + 0.3, cav_w/2 - 1, outer_w/2 + 1);
            xcyl(5.0, outer_w/2 - 0.8, outer_w/2 + 1);
        }
    }
}

// triangular ridge along X, tip `h` below z = 0 (45 degree flanks), standing on `base` above it
module ridge(len, h, base=0) hull() {
    translate([-len/2, -h - base, base]) cube([len, 2*(h + base), 0.01]);
    translate([-len/2, -0.005, -h]) cube([len, 0.01, 0.01]);
}

/* ---------------- lid ---------------- */
module lid() {
    difference() {
        intersection() {
            // the outline, chamfered round its outer face
            hull() {
                outline(0, z_back, z_lid1 - 0.3);
                outline(0.3, z_lid1 - 0.01, z_lid1);
            }
            union() {
                translate([-lid_hw, near_y - 1, z_back]) cube([2*lid_hw, lid_y1 - near_y + 1, lid_t]);
                translate([-lid_hw - tongue_w, near_y - 1, z_back + tongue_z0])
                    cube([2*(lid_hw + tongue_w), lid_y1 - near_y + 1, tongue_z1 - tongue_z0]);
            }
        }
        // the finger: a slot through the lid each side of it, from the near edge in, and
        // thinned from inside
        for (sx=[-1,1]) translate([finger_x + sx*(finger_w/2 + slot_w/2) - slot_w/2, near_y - 1, z_back - 1])
            cube([slot_w, finger_l + 1, lid_t + 2]);
        translate([finger_x - finger_w/2 - 0.01, near_y + wall_end + 0.4, z_back - 1])
            cube([finger_w + 0.02, finger_l - wall_end - 0.4, 1 + lid_t - finger_t]);
        // mount magnets: pockets in the outer face (glue them in; they stand mag_proud out)
        for (m=mag_xy) translate([m[0], m[1], z_lid1 - (lid_t - mag_floor)])
            cylinder(d=mag_d + 2*mag_lid_fit, h=lid_t, $fn=48);
        // pocket over the wheel, open at the far end so the lid slides past it (only when the
        // case is too shallow for the wheel)
        if (lid_pocket) translate([wheel_x0 - 0.4, wheel_y - lid_pocket_hl, z_back - 1])
            cube([wheel_x1 - wheel_x0 + 0.8, lid_y1 - (wheel_y - lid_pocket_hl) + 1,
                  1 + wheel_z + wheel_r + wheel_lid_clear - z_back]);
    }
    // the finger's ridge, under its end, over the end wall
    intersection() {
        translate([finger_x, near_y + wall_end/2, z_back]) ridge(ridge_w, ridge_h, 0.4);
        translate([finger_x - finger_w/2, near_y, z_back - 1]) cube([finger_w, wall_end + 1, 1.5]);
    }
}

/* ---------------- magnetic accessories (as voltra_ring's) ---------------- */
module mount_magnet_pockets() for (m=mag_xy) translate([m[0], m[1], z_lid1]) {
    translate([0, 0, -0.01]) cylinder(d=mag_d + 2*mag_fit, h=acc_hole + 0.01, $fn=48);
    translate([0, 0, -0.01]) cylinder(d=mag_d + 2*mag_slide, h=acc_slide + 0.01, $fn=48);
    translate([0, 0, -0.01]) cylinder(d1=mag_d + 2*(mag_slide + mag_lead) + 0.02, d2=mag_d + 2*mag_slide,
                                      h=mag_lead + 0.01, $fn=48);
}
module lid_magnets_mock() color("silver") for (m=mag_xy) translate([m[0], m[1], z_lid1 - (lid_t - mag_floor)])
    cylinder(d=mag_d, h=mag_t, $fn=48);
module acc_magnets_mock() color("silver") for (m=mag_xy) translate([m[0], m[1], z_lid1 + acc_hole - mag_t])
    cylinder(d=mag_d, h=mag_t, $fn=48);

module annulus_arc(c, r0, r1, a0, a1) translate(c) intersection() {
    difference() { circle(r=r1, $fn=128); circle(r=r0, $fn=128); }
    polygon(concat([[0,0]], [for (a=[a0:(a1-a0)/24:a1]) 3*r1*[cos(a), sin(a)]]));
}
module clip_place(x0, x1) translate([x0, clip_yc, z_lid1]) rotate([90,0,90]) linear_extrude(x1 - x0) children();
module dovetail_2d(a, f=0) translate([0, hc_w]) rotate(a) translate([seat_r, 0])
    polygon([[-0.5, -dv_n/2 - f], [0, -dv_n/2 - f], [dv_h + f, -dv_w/2 - f],
             [dv_h + f, dv_w/2 + f], [0, dv_n/2 + f], [-0.5, dv_n/2 + f]]);
module liner_grooves(angles) clip_place(-clip_w/2 + dv_stop, clip_w) for (a=angles) dovetail_2d(a, dv_fit);
module wedge_2d(a0, a1, r) polygon(concat([[0,0]], [for (a=[a0:(a1-a0)/24:a1]) r*[cos(a), sin(a)]]));

module clip_a() difference() {
    clip_place(-clip_w/2, clip_w/2) difference() {
        union() {
            translate([ja_u0, ja_top]) square([tail_u1 - ja_u0, ja_t]);
            translate([0, hc_w]) intersection() {
                circle(r=seat_r + sa_wall, $fn=128);
                wedge_2d(-90 - sa_m, -90 + sa_p, 2*seat_r);
            }
        }
        translate([0, hc_w]) circle(r=seat_r, $fn=128);
    }
    mount_magnet_pockets();
    liner_grooves([ka_a]);
    clip_place(-knuckle_w/2 - 0.3, knuckle_w/2 + 0.3) {
        translate([piv_u, piv_w]) circle(r=piv_r + 0.35, $fn=48);
        translate([piv_u - piv_r - 1.2, piv_w]) square([2*piv_r + 1.55, 30]);
    }
    clip_place(-clip_w, clip_w) translate([piv_u, piv_w]) circle(d=pin_d, $fn=24);
    translate([0, clip_yc + spring_u, z_lid1 + ja_bot - pocket_a]) cylinder(d=spring_od + 0.7, h=pocket_a + 1);
}

module clip_b() difference() {
    union() {
        clip_place(-clip_w/2, clip_w/2) union() {
            annulus_arc([0, hc_w], seat_r, seat_r + jaw_wall, c_a0, c_a1);
            translate([14, tb_top]) square([tail_u1 - 14, tb_bot - tb_top]);
        }
        clip_place(-knuckle_w/2, knuckle_w/2) hull() {
            translate([piv_u, piv_w]) circle(r=piv_r, $fn=48);
            translate([0, hc_w] + (seat_r + jaw_wall/2)*[cos(c_a0), sin(c_a0)]) circle(r=jaw_wall/2, $fn=32);
        }
    }
    clip_place(-clip_w, clip_w) translate([0, hc_w]) circle(r=seat_r, $fn=128);
    liner_grooves(kb_a);
    clip_place(-clip_w, clip_w) translate([piv_u, piv_w]) circle(d=pin_d, $fn=24);
    translate([0, clip_yc + spring_u, z_lid1 + tb_top - 1]) cylinder(d=spring_od + 0.7, h=pocket_b + 1);
}

module liner(a0, a1, keys) {
    n = floor((a1 - a0) / (grip_pitch/hr*180/PI));
    step = (a1 - a0) / n;
    clip_place(-clip_w/2, clip_w/2) translate([0, hc_w]) {
        annulus_arc([0, 0], hr + grip_h, seat_r, a0, a1);
        for (a=[a0 + step/2 : step : a1 - step/4]) rotate(a) translate([hr + grip_h + 0.1, 0]) circle(r=grip_h + 0.1, $fn=20);
    }
    clip_place(-clip_w/2 + dv_stop + 0.3, clip_w/2) for (a=keys) dovetail_2d(a);
}
module liner_a() liner(-90 - sa_m, -90 + sa_p, [ka_a]);
module liner_b() liner(c_a0, c_a1, kb_a);

module clip() { color("steelblue") clip_a(); color("slategray") clip_b(); color("darkorange") { liner_a(); liner_b(); }
                spring_mock(); pin_mock(); }
module spring_mock() color("silver") translate([0, clip_yc + spring_u, z_lid1 + ja_bot - pocket_a])
    difference() { cylinder(d=spring_od, h=spring_il, $fn=32); translate([0,0,-1]) cylinder(d=spring_od - 1.6, h=spring_il + 2, $fn=32); }
module pin_mock() color("silver") translate([0, clip_yc + piv_u, z_lid1 + piv_w]) xcyl(2.0, -clip_w/2, clip_w/2);
module handle_mock() color("tan") translate([-30, clip_yc, z_lid1 + hc_w]) xcyl(handle_d, 0, 60);

module band(sw = strap_w) difference() {
    translate([0, 0, z_lid1]) hull() {
        translate([0, 0, 0.4]) linear_extrude(band_th - 0.8)
            translate([0, (band_y0 + band_y1)/2]) rrect2d(band_w, band_y1 - band_y0, 3);
        linear_extrude(band_th)
            translate([0, (band_y0 + band_y1)/2]) rrect2d(band_w - 0.8, band_y1 - band_y0 - 0.8, 2.6);
    }
    mount_magnet_pockets();
    translate([-band_w, mount_yc - (sw + 0.8)/2, z_lid1 + band_top]) cube([2*band_w, sw + 0.8, strap_t]);
}
module strap_mock(sw = strap_w) color("black", 0.8)
    translate([-25, mount_yc - sw/2, z_lid1 + band_top + 0.4]) cube([50, sw, 1.6]);

module clip_a_print() translate([0, -clip_yc, -z_lid1]) clip_a();
module clip_b_print() translate([0, 0, clip_w/2]) rotate([0,-90,0]) translate([0, -clip_yc, -z_lid1]) clip_b();
module liner_print() translate([0, 0, clip_w/2]) rotate([0,90,0]) translate([0, -clip_yc, -z_lid1]) children();
module band_print(sw = strap_w) translate([0, 0, band_th]) rotate([180,0,0]) translate([0, -mount_yc, -z_lid1]) band(sw);

/* ---------------- printed controls parts (modelled in place) ---------------- */
module wheel() {
    x0 = wheel_x0 + wheel_trim;   // the wheel's encoder-side face (wheel_x0 is the space it turns in)
    translate([0, wheel_y, wheel_z]) difference() {
        intersection() {
            xcyl(wheel_d, x0, wheel_x1);
            hull() {                                   // small chamfers on both rims
                xcyl(wheel_d - 1.0, x0, wheel_x1);
                xcyl(wheel_d, x0 + 0.5, wheel_x1 - 0.5);
            }
        }
        for (i=[0:wheel_ribs-1]) rotate([360*i/wheel_ribs, 0, 0])
            translate([x0 + 1.2, 0, wheel_r - groove_dp + groove_w/2]) rotate([0,90,0])
                cylinder(d=groove_w, h=wheel_x1 - x0 - 2.4, $fn=16);
        // bore: round clearance most of the way, snug hex at the encoder end that drives the wheel
        xcyl(pass_d, x0 + drive_len - 0.01, wheel_x1 + 1);
        xhex(drive_bore, x0 - 1, x0 + drive_len);
    }
}

module shaft() {   // prints standing on its head
    translate([0, wheel_y, wheel_z]) {
        xcyl(4.6, outer_w/2 - 0.8, outer_w/2);                       // head, in the counterbore
        xcyl(shaft_d, cav_w/2 - 0.2, outer_w/2);                     // bearing section, in the side wall
        xhex(drive_af, wheel_x0 + 0.2, cav_w/2 - 0.2 + 0.01);        // drive hex, through the wheel
        xhex(key_print, enc_x1 - key_len, wheel_x0 + 0.2 + 0.01);    // tip, into the encoder
    }
}

module button() {
    translate([sw_xc, 0, btn_zc]) rotate([-90,0,0]) {   // local z = case +Y
        // bar through the end wall, standing proud, chamfered round the pressing face
        hull() {
            translate([0,0,end_y0 - 0.01]) linear_extrude(end_t + btn_proud - btn_ch + 0.01)
                rrect2d(btn_w, btn_hgt, 1.0);
            translate([0,0,end_y1 + btn_proud - 0.01]) linear_extrude(0.01)
                rrect2d(btn_w - 2*btn_ch, btn_hgt - 2*btn_ch, 1.0 - btn_ch);
        }
        // retaining wings above and below, inside the wall
        translate([0,0,end_y0 - btn_lip_t]) linear_extrude(btn_lip_t)
            rrect2d(btn_w, btn_hgt + 2*btn_lip, 1.0);
        // plunger pin back to the switch (full bar width, so the part prints flat on its side)
        translate([0,0,pin_y0]) linear_extrude(pin_len + 0.01)
            square([btn_w, btn_pin_w], center=true);
    }
}

// fit test, printed the same way as the real parts (see voltra_ring for the method)
fit_keys  = [1.75, 1.80, 1.85, 1.90];
fit_bores = [2.60, 2.70, 2.80, 2.90, 3.00];
module fit_pin(af, h) {
    cylinder(d=af/cos(30) + 2.4, h=1.0);
    linear_extrude(h) hex2d(af);
}
module fit_tips() {
    for (i=[0:len(fit_keys)-1]) translate([i*10, 0, 0]) {
        translate([-4.5, -6, 0]) cube([9, 4.5, 1.0]);
        translate([0, -3.75, 0.99]) linear_extrude(0.6)
            text(str(fit_keys[i]), size=2.0, halign="center", valign="center");
        fit_pin(fit_keys[i], key_len + 3);
    }
}
module fit_test() {
    fit_tips();
    translate([45, -2, 0]) fit_pin(drive_af, drive_len + 4);
    translate([-5, -21, 0]) difference() {
        cube([len(fit_bores)*10, 13, drive_len]);
        for (i=[0:len(fit_bores)-1]) translate([5 + i*10, 0, 0]) {
            translate([0, 8.6, -1]) linear_extrude(drive_len + 2) hex2d(fit_bores[i]);
            translate([0, 3.2, drive_len - 0.5]) linear_extrude(1)
                text(str(fit_bores[i]), size=2.2, halign="center", valign="center");
        }
    }
}

/* ---------------- protoboard (shape to cut) ---------------- */
module protoboard2d()   // in the board plane: X across, Y here = -case Z (display edge at the top)
    translate([pb_x0, -pb_z1]) square([pb_x1 - pb_x0, pb_z1 - pb_z0]);
module template2d() {   // board outline (seen from the component side) with parts engraved
    difference() {
        protoboard2d();
        translate([enc_x0, -wheel_z - enc_w/2]) difference() {
            square([enc_t, enc_w]); translate([0.4,0.4]) square([enc_t-0.8, enc_w-0.8]);
        }
        translate([enc_x0 - 0.01, -wheel_z - 0.2]) square([enc_t + 0.4, 0.4]);
        translate([sw_xc - sw_body/2, -btn_zc - sw_body/2]) difference() {
            square([sw_body, sw_body]); translate([0.4,0.4]) square([sw_body-0.8, sw_body-0.8]);
        }
        translate([sw_xc, -btn_zc]) circle(d=1.0);
    }
}
module protoboard_mock() color("darkgreen")
    translate([0, pb_y1, 0]) rotate([90,0,0]) linear_extrude(pb_t) mirror([0,1,0]) protoboard2d();

/* ---------------- reference models (for checking only) ---------------- */
module xiao_mock() {   // lying on its back: parts up, USB-C at -X
    color("royalblue") translate([xiao_x0, xiao_y0, xiao_z0]) cube([xiao_l, xiao_w, xiao_pcb_t]);
    color("silver") translate([xiao_x0 - usb_over, xiao_yc - usb_w/2, xiao_z1]) cube([7.4, usb_w, usb_h]);
    color("gray") translate([xiao_x0 + 9, xiao_yc - 6.5, xiao_z1]) cube([9, 13, 2.2]);     // shield can
    color("white") translate([xiao_x1 - 3, xiao_yc - 1.5, xiao_z1]) cube([2, 3, 1.2]);    // antenna
}
module oled_mock() {
    color("black") translate([oled_aa_dx - 14.5/2, oled_yc + oled_aa_dy - 11.6/2, face_t]) cube([14.5, 11.6, oled_glass_t]);
    color("white") translate([oled_aa_dx - oled_aa_w/2, oled_yc + oled_aa_dy - oled_aa_l/2, face_t - 0.01]) cube([oled_aa_w, oled_aa_l, 0.02]);
    color("darkgreen") translate([-oled_pcb_w/2, oled_y0, face_t + oled_glass_t]) cube([oled_pcb_w, oled_pcb_l, oled_pcb_t]);
}
module battery_mock() color("darkorange")
    translate([-bat_x/2, bat_y0, bat_z0]) cube([bat_x, bat_y, bat_h]);
module encoder_mock() color("dimgray")
    translate([enc_x0, pb_y1, wheel_z - enc_w/2]) cube([enc_t, wheel_y + enc_top - pb_y1, enc_w]);
module switch_mock() {
    color("black") translate([sw_xc - sw_body/2, pb_y1, btn_zc - sw_body/2]) cube([sw_body, sw_body_h, sw_body]);
    color("gray") translate([sw_xc, pb_y1, btn_zc]) rotate([-90,0,0]) cylinder(d=sw_plunger, h=sw_h);
}
module controls_mock() { protoboard_mock(); encoder_mock(); switch_mock(); }
module insides_mock() { xiao_mock(); oled_mock(); battery_mock(); controls_mock(); }

// print orientations
module wheel_print() translate([0,0,wheel_x1]) rotate([0,90,0]) translate([0, -wheel_y, -wheel_z]) wheel();
module shaft_print()   // standing on its head, tip up (use a brim)
    translate([0,0,outer_w/2]) rotate([0,90,0]) translate([0, -wheel_y, -wheel_z]) shaft();
module button_print()   // on its side, so the layer lines run the way it slides
    translate([0, 0, btn_w/2]) rotate([0, 90, 0]) translate([-sw_xc, -end_y0, -btn_zc]) button();
// outer face on the bed: turned over (a mirror would print the lid handed the wrong way round)
module lid_print() translate([0, 0, z_lid1]) rotate([180, 0, 0]) lid();

/* ---------------- output ---------------- */
if (part == "tub") tub();                   // print display-face down
else if (part == "lid") lid_print();        // outer face on the bed, no supports
else if (part == "wheel") wheel_print();
else if (part == "shaft") shaft_print();
else if (part == "button") button_print();
else if (part == "template") template2d();
else if (part == "fit_test") fit_test();
else if (part == "fit_tips") fit_tips();
else if (part == "clip_a") clip_a_print();
else if (part == "clip_b") clip_b_print();
else if (part == "liner_a") liner_print() liner_a();
else if (part == "liner_b") liner_print() liner_b();
else if (part == "band_20" || part == "band") band_print();   // for a 20 mm strap
else if (part == "band_13") band_print(strap_w_narrow);   // the same plate for a 1/2" strap
else if (part == "lid_asm") lid();
else if (part == "insides") insides_mock();
else if (part == "mount") { color("lightgray") tub(); color("dimgray") lid(); lid_magnets_mock();
                            color("orange") wheel(); color("red") button(); clip(); acc_magnets_mock(); handle_mock(); }
else if (part == "mount_band") { color("lightgray") tub(); color("dimgray") lid(); lid_magnets_mock();
                            color("orange") wheel(); color("red") button(); color("steelblue") band(); acc_magnets_mock(); strap_mock(); }
else if (part == "section") intersection() {      // cut along the case, through the switch
    union() { color("lightgray") tub(); color("dimgray") lid(); insides_mock();
              color("orange") wheel(); color("red") button(); }
    translate([sw_xc, -50, -10]) cube([50, 130, 50]);
}
else if (part == "section_wheel") intersection() {   // cut along the case, through the wheel
    union() { color("lightgray") tub(); color("dimgray") lid(); insides_mock();
              color("orange") { wheel(); shaft(); } color("red") button(); }
    translate([(wheel_x0 + wheel_x1)/2, -50, -10]) cube([50, 130, 50]);
}
else if (part == "section_across") intersection() {   // cut across the case, through the stack
    union() { color("lightgray") tub(); color("dimgray") lid(); insides_mock(); }
    translate([-50, xiao_yc, -10]) cube([100, 130, 50]);
}
else if (part == "print") {
    tub();
    translate([outer_w + 8, 0, 0]) lid_print();
    translate([-outer_w - 6, 0, 0]) wheel_print();
    translate([-outer_w - 6, 22, 0]) shaft_print();
}
else if (part == "exploded") {
    color("lightgray") tub();
    translate([0,0,-12]) oled_mock();
    translate([0,0,16]) battery_mock();
    translate([0,0,26]) xiao_mock();
    translate([0,0,14]) controls_mock();
    color("orange") translate([0,8,-10]) wheel();
    color("red") translate([0,8,0]) button();
    color("orange") translate([16,0,0]) shaft();
    color("dimgray") translate([0,-20,34]) lid();
}
else {  // assembled
    color("lightgray") tub();
    insides_mock();
    color("orange") { wheel(); shaft(); }
    color("red") button();
    color("dimgray") lid();
    lid_magnets_mock();
}
