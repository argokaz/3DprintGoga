// ============================================================
//  Visera frontal para Nintendo Switch 2
//  Protege los joysticks (capuchas rígidas) y la pantalla de rayones
//  (piel fina: la pantalla ya lleva cristal templado).
//
//  Sujeción v2 (sin dedos sueltos):
//   - Canal rígido abajo: abraza el borde inferior y engancha detrás.
//   - Solapa ancha arriba: se encaja a presión al cerrar la visera.
//   - Paredes de centrado en los extremos de los Joy-Con.
//  Se pone metiendo primero el borde inferior en el canal y bajando
//  la visera hasta que la solapa hace clic. Se quita tirando de la
//  pestaña de la solapa.
//
//  Coordenadas: X = largo, Y = alto, Z = hacia fuera de la pantalla.
//  La cara frontal de la consola está en z = 0.
// ============================================================

/* [Qué generar] */
// a1_diag | full | test_grip | test_hood
part = "a1_diag";
// light = piel fina + nervios bajos (pantalla con cristal templado) | ribbed = panel profundo antiaplastamiento
screen_style = "light";

/* [Consola (mide la tuya con calibre)] */
console_L = 272;    // largo con Joy-Con 2
console_H = 116;    // alto
console_T = 13.9;   // grosor del cuerpo
corner_r  = 11;     // radio de las esquinas exteriores (vista frontal)
joycon_w  = 35.5;   // ancho visible del Joy-Con 2 = (272 - 201 tablet) / 2
stick_h   = 7.2;    // punta del stick sobre la cara (dbrand 6.27; 30.7-14.4-9.1 = 7.2)

/* [Holguras] */
tol        = 0.4;   // holgura perimetral
stick_clear = 6.0;  // aire sobre la punta del stick (margen para que la capucha ceda sin tocarlo)
screen_gap = 1.8;   // altura del apoyo perimetral sobre el marco

/* [Estructura] */
wall      = 1.2;    // espesor de paredes
rim       = 3.0;    // ancho del apoyo perimetral sobre el marco
bezel_over = 5;     // cuánto entra la capucha sobre el marco de la tablet
skirt     = 3.0;    // faldón de centrado (hacia la parte trasera)

/* [Pantalla (estilo light)] */
light_skin = 1.0;   // piel sobre la pantalla: 5 capas de 0.2, maciza (sin agujeros: nada la raya)
light_rib_h = 4.0;  // nervios bajos bajo la piel (planitud y rigidez, ~10 mm sobre el cristal)
light_rib_t = 1.2;
light_rib_pitch = 40;

/* [Sujeción v2] */
// Canal inferior rígido (no flexa)
chan_hx   = 96;     // medio largo del canal (|x| <= chan_hx, tramo recto de la visera)
chan_t    = 2.4;    // espesor de su pared
chan_lip  = 2.6;    // cuánto engancha detrás de la consola (gancho a 45°)
// Solapa superior (lo único que flexa: ancha y larga, ver sim/)
flap_x    = [-25, 90];  // tramo X. Fuera quedan power/volumen (arriba a la izquierda)
flap_t    = 1.2;
flap_hook = 1.6;    // engancha flap_hook - tol detrás de la consola (gancho a 45°)
flap_slot = 1.0;    // ranuras laterales que la separan de la pared
flap_beam = 6.0;    // viga bajo la piel en la raíz de la solapa (alto; ancho = flap_beam + 2)
flap_tab  = 3.0;    // pestaña para soltarla
// pies de apoyo continuos sobre el marco (arriba bajo la viga de la solapa y abajo
// junto al canal): la visera apoya en la consola también en esos tramos
foot_t    = 1.6;
foot_in   = 7.7;    // (solapa 0.3 con la viga) distancia del pie al borde de la consola (queda sobre el marco, fuera de la pantalla)
// Paredes de centrado en los extremos (sin gancho)
end_hy    = 20;     // medio alto (tramo recto del extremo)
end_depth = 7;      // cuánto bajan por el canto del Joy-Con

/* [Rigidez (validada por FEA, ver sim/)] */
hood_t  = 2.6;      // techo de las capuchas sobre los sticks
skin_t  = 1.4;      // piel exterior sobre la pantalla (1.4: FEA, rodilla de 30 kg)
rib_h   = 10.6;     // profundidad del panal interior sobre la pantalla (deja 3.8 mm de aire)
core_s  = 14;       // celda del panal interior (entre caras planas)
core_rib = 1.4;     // espesor de sus nervios
// zona de pantalla (estimada +1 mm): fuera de ella los nervios bajan en rampa
// de 45° hasta el apoyo, sin esquinas vivas (FEA)
hood_rib_h = 3.4;   // panal bajo el techo de las capuchas (deja stick_clear - 3.4 mm sobre el stick)
hood_rib_t = 1.8;   // espesor de sus nervios
hood_gusset = 5.5;  // refuerzo a 45° techo/pared de apoyo (cubre el borde inferior del panal)
screen_hw = 88.5;
screen_hh = 50;

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
    if (screen_style == "honeycomb")
        intersection() { square([w, h], center=true); hex_grid(w, h); }
    else if (screen_style == "open")
        square([w, iH - 2*bar_w], center=true);
}

module screen_zone2d() { intersection() { cover2d(0); halfplane_in(B); } }
module core2d() {   // nervios del panal interior
    intersection() {
        offset(delta=eps) screen_zone2d();
        difference() { square([iL, iH], center=true); hex_grid(iL, iH, core_s, core_rib); }
    }
}

// panal poco profundo bajo el techo de las capuchas + refuerzo en la pared de apoyo
module hood_zone2d() { intersection() { cover2d(0); halfplane_out(B + wall); } }
module hood_ribs() {
    translate([0, 0, hood_in - hood_rib_h]) linear_extrude(hood_rib_h + eps)
        intersection() {
            offset(delta=eps) hood_zone2d();
            difference() { square([iL, iH], center=true); hex_grid(iL, iH, core_s + core_rib - hood_rib_t, hood_rib_t); }
        }
    intersection() {
        linear_extrude(top_z) cover2d(eps);
        for (sx = [-1, 1]) mirror([sx < 0 ? 1 : 0, 0, 0])
            translate([B + wall - eps, 0, hood_in + eps]) rotate([90, 0, 0])
                linear_extrude(iH, center=true) polygon([[0, 0], [hood_gusset, 0], [0, -hood_gusset]]);
    }
}

// hueco bajo los nervios sobre la pantalla, con paredes a 45° hacia el marco
module rib_pit() {
    hull() {
        translate([0, 0, rib_bot]) linear_extrude(eps) square([2*screen_hw, 2*screen_hh], center=true);
        translate([0, 0, screen_gap - eps]) linear_extrude(eps)
            offset(delta=rib_bot - screen_gap) square([2*screen_hw, 2*screen_hh], center=true);
    }
}

module hood_vents2d() {
    intersection() {
        offset(r=-3) intersection() { cover2d(0); halfplane_out(B + wall); }
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

// ---------- sujeción v2 ----------
zb = -(console_T + tol);   // plano trasero de la consola (con holgura)

// perfil de gancho a 45° (imprimible boca abajo): ancho d hacia dentro
module hook2d(d, h) { polygon([[0, 0], [d, -d], [d, -d - h], [0, -d - h]]); }
// diente: cara de retención a 45° arriba y rampa de entrada a 45° abajo
module tooth2d(d) { polygon([[0, 0], [d, -d], [0, -2*d]]); }

// canal inferior: pared + gancho, en marco local (borde según X, +Y hacia fuera)
module channel() {
    translate([-chan_hx, 0, 0]) rotate([90, 0, 90]) linear_extrude(2*chan_hx)
        union() {
            translate([0, zb - chan_lip - 1.2]) square([chan_t, -zb + chan_lip + 1.2 + eps]);
            translate([0, zb]) mirror([1, 0]) hook2d(chan_lip, 1.2);
        }
}

// solapa superior: pared colgada de una viga, gancho a 45° y pestaña
flap_root = top_z - flap_beam;
module flap() {
    w = flap_x[1] - flap_x[0];
    translate([flap_x[0], 0, 0]) rotate([90, 0, 90]) linear_extrude(w)
        union() {
            translate([0, zb - 2*flap_hook]) square([flap_t, top_z - (zb - 2*flap_hook)]);
            translate([0, zb]) mirror([1, 0]) tooth2d(flap_hook);
            // pestaña hacia fuera en el extremo, a 45° (imprimible boca abajo)
            translate([flap_t, zb - 2*flap_hook]) polygon([[0, 0], [flap_tab, 0], [0, flap_tab]]);
        }
}
// lo que hay que vaciar para que la solapa flexe libre
module flap_relief() {
    w = flap_x[1] - flap_x[0];
    // ranuras laterales hasta la viga, con agujero de alivio arriba
    for (x = flap_x) {
        translate([x - flap_slot/2, -rim - 2, zb - 20]) cube([flap_slot, rim + flap_t + 4, flap_root - zb + 20]);
        translate([x, -rim - 2, flap_root]) rotate([-90, 0, 0]) cylinder(d=2*flap_slot, h=rim + flap_t + 4, $fn=24);
    }
    // por dentro: sin apoyo ni pared detrás de la solapa
    translate([flap_x[0] + flap_slot/2, -rim - 2, -1]) cube([w - flap_slot, rim + 2, flap_root + 1]);
}
flap_fillet = 2.0;  // redondeo solapa/viga (sin él la raíz concentra la tensión: FEA)
module feet() {
    // arriba: bajo la viga, a lo largo de la solapa; abajo: a lo largo del canal
    translate([flap_x[0] - 3, iH/2 - foot_in - foot_t, 0]) cube([flap_x[1] - flap_x[0] + 6, foot_t, top_z - eps]);
    translate([-chan_hx, -iH/2 + foot_in, 0]) cube([2*chan_hx, foot_t, top_z - eps]);
}
module flap_beam() {   // raíz rígida: viga maciza bajo la piel a lo largo de la solapa
    w = flap_x[1] - flap_x[0] + 6;
    translate([flap_x[0] - 3, -flap_beam - 2, flap_root]) cube([w, flap_beam + 2, flap_beam]);
    translate([flap_x[0] - 3, 0, 0]) difference() {
        translate([0, -flap_fillet, flap_root - flap_fillet]) cube([w, flap_fillet + eps, flap_fillet + eps]);
        translate([-1, -flap_fillet, flap_root - flap_fillet]) rotate([0, 90, 0]) cylinder(r=flap_fillet, h=w + 2, $fn=32);
    }
}

// paredes de centrado en los extremos (sin gancho: no estorban al cerrar)
module end_wall() {
    translate([-end_hy, 0, -end_depth]) cube([2*end_hy, wall, end_depth + eps]);
}

module at_edges() {
    translate([0, -iH/2, 0]) rotate([0, 0, 180]) children(0);         // canal abajo
    translate([0,  iH/2, 0]) children(1);                              // solapa arriba
    for (sx = [-1, 1]) translate([sx*iL/2, 0, 0]) rotate([0, 0, -sx*90]) children(2);
}

// piel fina con nervios bajos (estilo light)
module light_ribs() {
    n = ceil(iL / light_rib_pitch);
    translate([0, 0, top_z - light_skin - light_rib_h]) linear_extrude(light_rib_h + eps)
        intersection() {
            offset(delta=-10) screen_zone2d();  // no tocan las paredes, la solapa ni los pies
            union() {
                for (i = [-n:n]) translate([i*light_rib_pitch - light_rib_t/2, -500]) square([light_rib_t, 1000]);
                for (j = [-2:2]) translate([-500, j*light_rib_pitch - light_rib_t/2]) square([1000, light_rib_t]);
            }
        }
}

module visera_base() {
    difference() {
        union() {
            // caja: cara exterior plana + paredes + faldón de centrado
            translate([0, 0, -skirt]) linear_extrude(skirt + top_z) cover2d(wall);
            at_edges() { channel(); flap(); end_wall(); }
        }
        // hueco de la consola: SOLO su volumen (hasta la cara trasera). Si siguiera
        // más atrás borraría los ganchos que enganchan detrás de ella.
        translate([0, 0, zb]) linear_extrude(-zb + eps) outline(0);
        // aire interior (sticks y pantalla), deja las paredes de apoyo en x = ±B
        translate([0, 0, screen_gap]) linear_extrude(hood_in - screen_gap)
            difference() { cover2d(0); for (s=[-1,1]) translate([s*(B + wall/2), 0]) square([wall, 1000], center=true); }
        // apoyo perimetral sobre el marco (ancho 'rim') y paredes x = ±B hasta la cara
        linear_extrude(screen_gap + eps)
            difference() { cover2d(-rim); for (s=[-1,1]) translate([s*(B + wall/2), 0]) square([wall, 1000], center=true); }
        // aligerado
        // zona de pantalla del estilo ribbed: hueco hasta la piel (luego se añade el panal)
        // zona de pantalla: hueco hasta la piel (luego se añaden nervios)
        translate([0, 0, hood_in - eps]) linear_extrude(top_z - (screen_style == "ribbed" ? skin_t : light_skin) - hood_in + eps) screen_zone2d();
        translate([0, 0, hood_in - 1]) linear_extrude(hood_t + 2) screen_cut2d();
        if (hood_vents) translate([0, 0, hood_in - 1]) linear_extrude(hood_t + 2) hood_vents2d();
        translate([0, iH/2, 0]) flap_relief();
        // sin apoyo a lo largo del canal: la consola entra inclinada sin rozar
        translate([-chan_hx, -iH/2 - eps, -1]) cube([2*chan_hx, rim + 1, screen_gap + 1 + eps]);
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
            if (screen_style == "light") light_ribs();
            translate([0, iH/2, 0]) intersection() { flap_beam(); translate([0, -iH/2, 0]) linear_extrude(top_z) cover2d(-eps); }
            feet();
            if (screen_style == "ribbed")
                difference() {
                    translate([0, 0, screen_gap]) linear_extrude(top_z - skin_t - screen_gap + eps) core2d();
                    rib_pit();
                }
            hood_ribs();
            if (magnets) magnet_bosses();
        }
        if (magnets) magnet_pockets();
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
else if (part == "test_grip") face_down() test_strip(30, 70);   // canal + solapa: prueba el agarre
else if (part == "sim_grip")  test_strip(30, 70);                // lo mismo sin girar (para sim/)
else if (part == "test_hood") face_down() test_strip(B - 1.5, console_L/2 + 5);
