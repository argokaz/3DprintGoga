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
// a1_diag | a1_plate | full | left | right | test_clip | test_hood (incluye abrazadera del extremo)
part = "a1_diag";
// ribbed = piel maciza + panal profundo por dentro (rígido, validado por FEA) | solid | honeycomb | open
screen_style = "ribbed";

/* [Consola (mide la tuya con calibre)] */
console_L = 272;    // largo con Joy-Con 2
console_H = 116;    // alto
console_T = 13.9;   // grosor del cuerpo
corner_r  = 11;     // radio de las esquinas exteriores (vista frontal)
joycon_w  = 35.5;   // ancho visible del Joy-Con 2 = (272 - 201 tablet) / 2
stick_h   = 7.2;    // punta del stick sobre la cara (dbrand 6.27; 30.7-14.4-9.1 = 7.2)

/* [Holguras] */
tol        = 0.4;   // holgura perimetral
stick_clear = 4.0;  // aire sobre la punta del stick (margen para que la capucha ceda sin tocarlo)
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
clip_t      = 1.4;   // espesor del dedo (1.4: equilibrio agarre / tensión, ver sim/)
clip_hook   = 1.0;   // cuánto engancha detrás de la consola (sube a 1.2 si queda floja)
clip_hook_t = 1.6;
slot_w      = 1.0;   // ranuras a los lados del dedo para que flexione entero
// El dedo arranca casi arriba de la pared (no en la cara de la consola): más
// largo = mucha menos tensión entre capas. Validado por FEA (sim/).
finger_root_z = 8.2;
top_clips    = [-45, 45];             // X desde el centro. Lejos de power/volumen, USB-C y L/R
bottom_clips = [-95, -40, 40, 95];    // libre el USB-C central
end_clip_w   = 40;                    // abrazaderas en los extremos redondeados de los Joy-Con
end_clips    = true;

/* [Rigidez (validada por FEA, ver sim/)] */
hood_t  = 2.0;      // techo de las capuchas sobre los sticks
skin_t  = 1.0;      // piel exterior sobre la pantalla (estilo ribbed)
rib_h   = 8.0;      // profundidad del panal interior sobre la pantalla
core_s  = 14;       // celda del panal interior (entre caras planas)
core_rib = 1.2;     // espesor de sus nervios

/* [Panal] */
hex_s   = 11;       // tamaño de celda (entre caras planas)
hex_rib = 1.4;      // espesor de nervio
bar_w   = 14;       // ancho de barras en el estilo "open"
// panal pequeño en el techo de las capuchas (celdas < stick, no entra nada)
hood_vents = false;  // false: techo macizo, mucho más resistente a la presión
vent_s  = 7;

/* [Imanes (opcional, experimental)] */
// Los Joy-Con 2 se sujetan a la tablet con imanes en el raíl. Un imán en la
// visera, justo sobre la junta Joy-Con/tablet, puede agarrarse a ellos.
// PRUEBA ANTES con un imán suelto: que se pegue y que la consola no reaccione.
magnets  = false;
magnet_d = 6;       // imán de disco 6 x 2 mm (N52)
magnet_h = 2;
magnet_y = [-20, 20];   // posiciones Y sobre cada junta (centro = 0)

/* [Impresión en diagonal (una sola pieza en camas de 256 mm)] */
// La visera se imprime girada 45°. Para que quepa, las esquinas de la
// visera se redondean más que las de la consola (solo dejan al aire un
// triángulo en cada esquina, donde no hay botones en la cara frontal).
diag_print = true;
bed        = 256;   // Bambu A1 (el A1 mini, 180 mm, no sirve)
bed_margin = 3;

/* [División para camas pequeñas] */
flange_t = 2.4;     // pestaña de unión
pin_d    = 2.2;     // M2 o filamento de 1.75

$fn = 48;

// ---------- derivadas ----------
iL = console_L + 2*tol;
iH = console_H + 2*tol;
hood_in  = stick_h + stick_clear;      // altura interior de la capucha
top_z = hood_in + hood_t;              // cara exterior plana
rib_bot = top_z - skin_t - rib_h;      // cara inferior de los nervios (aire hasta la pantalla)
B = console_L/2 - joycon_w - bezel_over;   // |x| donde empieza la capucha
eps = 0.01;

// radio de esquina de la visera necesario para caber a 45° en la cama
ox = iL/2 + wall;  oy = iH/2 + wall;
diag_lim = (bed - 2*bed_margin) / sqrt(2);          // |x| + |y| <= diag_lim
cover_r  = diag_print ? max(corner_r + wall, (ox + oy - diag_lim) / (2 - sqrt(2)) + 0.5) : corner_r + wall;

// contorno de la visera (contorno de la consola ∩ esquinas grandes), desplazado d
module cover2d(d=0) {
    intersection() {
        outline(d);
        offset(r=cover_r - wall + d) square([2*ox - 2*cover_r, 2*oy - 2*cover_r], center=true);
    }
}

// contorno frontal desplazado d mm
module outline(d=0) {
    r = max(corner_r + d, 0.5);
    offset(r=r) square([iL + 2*d - 2*r, iH + 2*d - 2*r], center=true);
}
module halfplane_out(x0) { // |x| >= x0
    for (s=[-1,1]) translate([s>0 ? x0 : -x0-1000, -500]) square([1000, 1000]);
}
module halfplane_in(x0) { translate([-x0, -500]) square([2*x0, 1000]); }

module hex_grid(w, h, cell=hex_s, rib=hex_rib) {
    p  = cell + rib;
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

module screen_zone2d() { intersection() { cover2d(-wall); halfplane_in(B); } }
module core2d() {   // nervios del panal interior
    intersection() {
        offset(delta=eps) screen_zone2d();
        difference() { square([iL, iH], center=true); hex_grid(iL, iH, core_s, core_rib); }
    }
}

module hood_vents2d() {
    intersection() {
        offset(r=-3) intersection() { cover2d(-wall); halfplane_out(B + wall); }
        hex_grid(iL, iH, vent_s);
    }
}

seam_x = console_L/2 - joycon_w;   // junta Joy-Con / tablet
module magnet_bosses() {
    for (sx = [-1, 1], y = magnet_y) translate([sx*seam_x, y, 0]) cylinder(d=magnet_d + 2.4, h=hood_in + eps);
}
module magnet_pockets() {
    for (sx = [-1, 1], y = magnet_y) translate([sx*seam_x, y, -1]) cylinder(d=magnet_d + 0.2, h=magnet_h + 1);
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
root_fillet = 1.5;  // redondeo en la raíz del dedo (quita la concentración de tensiones)
module finger_slots(w) {
    // ranuras laterales a todo lo alto del dedo, terminadas en agujero de alivio
    for (sx = [-1, 1]) translate([sx*(w/2 + slot_w/2), 0, 0]) {
        translate([-slot_w/2, -rim - 1, -skirt - 1]) cube([slot_w, rim + wall + 2, skirt + 1 + finger_root_z]);
        translate([0, -rim - 1, finger_root_z]) rotate([-90, 0, 0]) cylinder(d=2*slot_w, h=rim + wall + 2, $fn=24);
    }
    // por dentro, el dedo queda con espesor clip_t, con redondeo en la raíz
    difference() {
        translate([-w/2 - slot_w, -rim - 1, -1]) cube([w + 2*slot_w, rim + 1, finger_root_z + 1]);
        difference() {
            translate([-w/2 - slot_w - 1, -root_fillet, finger_root_z - root_fillet]) cube([w + 2*slot_w + 2, root_fillet + eps, root_fillet + eps]);
            translate([-w/2 - slot_w - 2, -root_fillet, finger_root_z - root_fillet]) rotate([0, 90, 0]) cylinder(r=root_fillet, h=w + 2*slot_w + 4, $fn=24);
        }
    }
}
// coloca hijos en cada posición de dedo (borde superior, inferior y extremos)
module at_clips() {
    for (x = top_clips)    translate([x,  iH/2, 0]) children(0);
    for (x = bottom_clips) translate([x, -iH/2, 0]) rotate([0, 0, 180]) children(0);
    if (end_clips) for (sx = [-1, 1]) translate([sx*iL/2, 0, 0]) rotate([0, 0, -sx*90]) children(1);
}

module visera_base() {
    difference() {
        union() {
            // caja: cara exterior plana + paredes + faldón de centrado
            translate([0, 0, -skirt]) linear_extrude(skirt + top_z) cover2d(wall);
            at_clips() { finger(clip_w); finger(end_clip_w); }
        }
        // hueco de la consola
        translate([0, 0, -console_T - 10]) linear_extrude(console_T + 10) outline(0);
        // aire interior (sticks y pantalla), deja las paredes de apoyo en x = ±B
        translate([0, 0, screen_gap]) linear_extrude(hood_in - screen_gap)
            difference() { cover2d(-wall); for (s=[-1,1]) translate([s*(B + wall/2), 0]) square([wall, 1000], center=true); }
        // apoyo perimetral sobre el marco (ancho 'rim') y paredes x = ±B hasta la cara
        linear_extrude(screen_gap + eps)
            difference() { cover2d(-rim); for (s=[-1,1]) translate([s*(B + wall/2), 0]) square([wall, 1000], center=true); }
        // aligerado
        // zona de pantalla del estilo ribbed: hueco hasta la piel (luego se añade el panal)
        if (screen_style == "ribbed" && part != "test_clip")
            translate([0, 0, hood_in - eps]) linear_extrude(top_z - skin_t - hood_in + eps) screen_zone2d();
        translate([0, 0, hood_in - 1]) linear_extrude(hood_t + 2) screen_cut2d();
        if (hood_vents) translate([0, 0, hood_in - 1]) linear_extrude(hood_t + 2) hood_vents2d();
        at_clips() { finger_slots(clip_w); finger_slots(end_clip_w); }
        // el faldón superior no debe pisar L/R ni ZL/ZR
        translate([0, 0, -skirt - 1]) linear_extrude(skirt + 1 - eps)
            intersection() {
                halfplane_out(B);
                translate([-500, iH/2 - rim]) square([1000, 50]);
            }
    }
}

module visera() {
    difference() {
        union() {
            visera_base();
            if (screen_style == "ribbed" && part != "test_clip")
                translate([0, 0, rib_bot]) linear_extrude(rib_h + eps) core2d();
            if (magnets) magnet_bosses();
        }
        if (magnets) magnet_pockets();
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
else if (part == "a1_diag")   rotate([0, 0, 45]) face_down() visera();   // una pieza, lista para la A1
else if (part == "a1_plate")  // las dos mitades en una cama de 256 x 256 (Bambu A1)
    for (sd = [-1, 1]) translate([sd*(iH/2 + wall + 4), 0, 0]) rotate([0, 0, 90]) translate([-sd*(iL/4 + wall/2), 0, 0]) face_down() half(sd);
else if (part == "left")      half(-1);
else if (part == "right")     half(1);
else if (part == "test_clip") test_strip(25, 65);
else if (part == "test_hood") test_strip(B - 1.5, console_L/2 + 5);
