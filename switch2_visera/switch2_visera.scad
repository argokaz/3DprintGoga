// ============================================================
//  Visera frontal ultraligera para Nintendo Switch 2
//  Protege la pantalla y evita que los joysticks se aplasten.
//
//  Idea clave: sobre cada Joy-Con hay una "capucha" (hood) que
//  cubre TODO el mando, así la posición exacta del stick no
//  importa. Toda la presión se apoya en el borde exterior y en
//  el marco entre pantalla y Joy-Con, nunca en sticks ni pantalla.
//
//  Coordenadas: X = largo, Y = alto, Z = hacia fuera de la pantalla.
//  La cara frontal de la consola está en z = 0.
// ============================================================

/* [Qué generar] */
// a1_plate | full | left | right | test_clip | test_hood (incluye abrazadera del extremo)
part = "full";
// solid = pantalla cubierta | honeycomb = panal (más ligero) | open = solo barras (ultraligero)
screen_style = "honeycomb";

/* [Consola (mide la tuya con calibre)] */
console_L = 272;    // largo con Joy-Con 2
console_H = 116;    // alto
console_T = 13.9;   // grosor del cuerpo
corner_r  = 11;     // radio de las esquinas exteriores (vista frontal)
joycon_w  = 35.5;   // ancho visible del Joy-Con 2 = (272 - 201 tablet) / 2
stick_h   = 7.2;    // punta del stick sobre la cara (dbrand 6.27; 30.7-14.4-9.1 = 7.2)

/* [Holguras] */
tol        = 0.4;   // holgura perimetral
stick_clear = 2.5;  // aire sobre la punta del stick
screen_gap = 1.8;   // aire entre la pantalla y la placa

/* [Estructura] */
wall      = 1.2;    // espesor de paredes y techo (3 perímetros de 0.4)
rim       = 3.0;    // ancho del apoyo perimetral sobre el marco
bezel_over = 5;     // cuánto entra la capucha sobre el marco de la tablet
skirt     = 3.0;    // faldón de centrado (hacia la parte trasera)

/* [Clips (dimensionados para PLA)] */
// Dedos que bajan por el canto y enganchan detrás de la consola.
// Con L≈16 mm, t=1.6 y gancho de 1 mm la deformación es ~1 %: segura en PLA.
clip_w      = 16;
clip_t      = 1.6;   // espesor del dedo
clip_hook   = 1.0;   // cuánto engancha detrás de la consola (sube a 1.2 si queda floja)
clip_hook_t = 1.6;
slot_w      = 1.0;   // ranuras a los lados del dedo para que flexione entero
top_clips    = [-45, 45];             // X desde el centro. Lejos de power/volumen, USB-C y L/R
bottom_clips = [-115, -45, 45, 115];  // libre el USB-C central; ±115 = bajo cada Joy-Con
end_clip_w   = 40;                    // abrazaderas en los extremos redondeados de los Joy-Con
end_clips    = true;

/* [Panal] */
hex_s   = 11;       // tamaño de celda (entre caras planas)
hex_rib = 1.4;      // espesor de nervio
bar_w   = 14;       // ancho de barras en el estilo "open"
// panal pequeño en el techo de las capuchas (celdas < stick, no entra nada)
hood_vents = true;
vent_s  = 7;

/* [División para camas pequeñas] */
flange_t = 2.4;     // pestaña de unión
pin_d    = 2.2;     // M2 o filamento de 1.75

$fn = 48;

// ---------- derivadas ----------
iL = console_L + 2*tol;
iH = console_H + 2*tol;
hood_in  = stick_h + stick_clear;      // altura interior de la capucha
top_z = hood_in + wall;                // cara exterior plana
B = console_L/2 - joycon_w - bezel_over;   // |x| donde empieza la capucha
eps = 0.01;

// contorno frontal desplazado d mm
module outline(d=0) {
    r = max(corner_r + d, 0.5);
    offset(r=r) square([iL + 2*d - 2*r, iH + 2*d - 2*r], center=true);
}
module halfplane_out(x0) { // |x| >= x0
    for (s=[-1,1]) translate([s>0 ? x0 : -x0-1000, -500]) square([1000, 1000]);
}
module halfplane_in(x0) { translate([-x0, -500]) square([2*x0, 1000]); }

module hex_grid(w, h, cell=hex_s) {
    p  = cell + hex_rib;
    dx = p * sqrt(3)/2;
    R  = cell / sqrt(3);
    nx = ceil(w/dx) + 1;  ny = ceil(h/p) + 1;
    for (i=[-nx:nx]) for (j=[-ny:ny])
        translate([i*dx, j*p + (i%2 ? p/2 : 0)]) circle(r=R, $fn=6);
}

// zona de la pantalla que se aligera
module screen_cut2d() {
    m = rim + 3;
    w = 2*(B - 3);  h = iH - 2*m;
    if (part == "test_clip") {}  // el probador sale macizo (sin trozos sueltos)
    else if (screen_style == "honeycomb")
        intersection() { square([w, h], center=true); hex_grid(w, h); }
    else if (screen_style == "open")
        square([w, iH - 2*bar_w], center=true);
}

module hood_vents2d() {
    intersection() {
        offset(r=-3) intersection() { outline(-wall); halfplane_out(B + wall); }
        hex_grid(iL, iH, vent_s);
    }
}

// Dedo genérico en un borde recto. Marco local: el borde va según X,
// +Y hacia fuera, la cara interior del dedo está en y = 0.
module finger(w) {
    zb = -(console_T + tol);
    translate([-w/2, 0, zb - clip_hook_t]) cube([w, clip_t, -zb + clip_hook_t + eps]);
    // gancho con rampa de entrada (45°)
    hull() {
        translate([-w/2, -clip_hook, zb - clip_hook_t]) cube([w, clip_hook + eps, 0.5]);
        translate([-w/2, 0, zb - clip_hook_t]) cube([w, eps, clip_hook_t + clip_hook]);
    }
}
module finger_slots(w) { // corta el faldón junto al dedo
    for (sx = [-1, 1]) translate([sx*(w/2 + slot_w/2) - slot_w/2, -1, -skirt - 1]) cube([slot_w, wall + 2, skirt + 1]);
}
// coloca hijos en cada posición de dedo (borde superior, inferior y extremos)
module at_clips() {
    for (x = top_clips)    translate([x,  iH/2, 0]) children(0);
    for (x = bottom_clips) translate([x, -iH/2, 0]) rotate([0, 0, 180]) children(0);
    if (end_clips) for (sx = [-1, 1]) translate([sx*iL/2, 0, 0]) rotate([0, 0, -sx*90]) children(1);
}

module visera() {
    difference() {
        union() {
            // caja: cara exterior plana + paredes + faldón de centrado
            translate([0, 0, -skirt]) linear_extrude(skirt + top_z) outline(wall);
            at_clips() { finger(clip_w); finger(end_clip_w); }
        }
        // hueco de la consola
        translate([0, 0, -console_T - 10]) linear_extrude(console_T + 10) outline(0);
        // aire interior (sticks y pantalla), deja las paredes de apoyo en x = ±B
        translate([0, 0, screen_gap]) linear_extrude(hood_in - screen_gap)
            difference() { outline(-wall); for (s=[-1,1]) translate([s*(B + wall/2), 0]) square([wall, 1000], center=true); }
        // apoyo perimetral sobre el marco (ancho 'rim') y paredes x = ±B hasta la cara
        linear_extrude(screen_gap + eps)
            difference() { outline(-rim); for (s=[-1,1]) translate([s*(B + wall/2), 0]) square([wall, 1000], center=true); }
        // aligerado
        translate([0, 0, hood_in - 1]) linear_extrude(wall + 2) screen_cut2d();
        if (hood_vents) translate([0, 0, hood_in - 1]) linear_extrude(wall + 2) hood_vents2d();
        at_clips() { finger_slots(clip_w); finger_slots(end_clip_w); }
        // el faldón superior no debe pisar L/R ni ZL/ZR
        translate([0, 0, -skirt - 1]) linear_extrude(skirt + 1 - eps)
            intersection() {
                halfplane_out(B);
                translate([-500, iH/2 - rim]) square([1000, 50]);
            }
    }
}

// ---------- división en dos mitades (camas < 280 mm) ----------
// Cada mitad lleva una pestaña interior en el corte (x = 0). Se unen
// con pegamento + 3 tornillos M2x8 (o trozos de filamento de 1.75).
module flange(side) {
    translate([side > 0 ? 0 : -flange_t, 0, screen_gap])
        rotate([90, 0, 90]) linear_extrude(flange_t)
            intersection() {
                translate([-500, 0]) square([1000, hood_in - screen_gap + eps]);
                translate([0, -screen_gap]) square([iH - 2*wall, 1000], center=true);
            }
}
module joint_holes() {
    for (y = [-iH/3, 0, iH/3])
        translate([0, y, (screen_gap + hood_in)/2]) rotate([0, 90, 0]) cylinder(d=pin_d, h=20, center=true, $fn=16);
}
module half(side) { // side = -1 izquierda, +1 derecha
    difference() {
        union() {
            intersection() {
                visera();
                translate([side > 0 ? 0 : -1000, -500, -100]) cube([1000, 1000, 200]);
            }
            flange(side);
            // banda sólida en la cara exterior junto al corte (para pegar)
            translate([side > 0 ? 0 : -flange_t*2, 0, hood_in]) linear_extrude(wall)
                intersection() { translate([0, -iH/2]) square([flange_t*2, iH]); outline(-wall/2); }
        }
        joint_holes();
    }
}

module test_strip(x0, x1) {
    intersection() {
        visera();
        translate([x0, -500, -100]) cube([x1 - x0, 1000, 200]);
    }
}

// boca abajo (cara exterior sobre la cama) para imprimir sin soportes
module face_down() { translate([0, 0, top_z]) rotate([180, 0, 0]) children(); }

if      (part == "full")      visera();
else if (part == "a1_plate")  // las dos mitades en una cama de 256 x 256 (Bambu A1)
    for (sd = [-1, 1]) translate([sd*(iH/2 + wall + 4), 0, 0]) rotate([0, 0, 90]) translate([-sd*(iL/4 + wall/2), 0, 0]) face_down() half(sd);
else if (part == "left")      half(-1);
else if (part == "right")     half(1);
else if (part == "test_clip") test_strip(25, 65);
else if (part == "test_hood") test_strip(B - 1.5, console_L/2 + 5);
