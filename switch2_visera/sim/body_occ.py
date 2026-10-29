"""Cuerpo de la visera para FEA, construido en CAD exacto (OpenCASCADE vía gmsh)
con los parámetros de switch2_visera.scad. Sin dedos de agarre ni faldón: no
intervienen en las cargas sobre pantalla y capuchas (la visera apoya en z = 0)."""
import math, os, re
import numpy as np
import gmsh

HERE = os.path.dirname(os.path.abspath(__file__))
SCAD = open(os.path.join(os.path.dirname(HERE), "switch2_visera.scad")).read()
def P(n): return float(re.search(rf"^{n}\s*=\s*([-0-9.]+)\s*;", SCAD, re.M).group(1))

L, H, tol, wall, rim = P("console_L"), P("console_H"), P("tol"), P("wall"), P("rim")
joycon_w, bezel_over = P("joycon_w"), P("bezel_over")
hood_in = P("stick_h") + P("stick_clear"); top_z = hood_in + P("hood_t")
skin_t, rib_h, core_s, core_rib, screen_gap = P("skin_t"), P("rib_h"), P("core_s"), P("core_rib"), P("screen_gap")
bed, margin, corner_r = P("bed"), P("bed_margin"), P("corner_r")
iL, iH = L + 2*tol, H + 2*tol
ox, oy = iL/2 + wall, iH/2 + wall
diag = (bed - 2*margin) / math.sqrt(2)
cover_r = max(corner_r + wall, (ox + oy - diag) / (2 - math.sqrt(2)) + 0.5)
B = L/2 - joycon_w - bezel_over
rib_bot = top_z - skin_t - rib_h

occ = None
def prism(d, z0, z1):
    """cover2d(d) del .scad extruido entre z0 y z1"""
    hx, hy, r = ox + d - wall, oy + d - wall, cover_r + d - wall
    f = occ.addRectangle(-hx, -hy, z0, 2*hx, 2*hy, roundedRadius=r)
    return [e for e in occ.extrude([(2, f)], 0, 0, z1 - z0) if e[0] == 3]
def box(x0, x1, y0, y1, z0, z1): return [(3, occ.addBox(x0, y0, z0, x1-x0, y1-y0, z1-z0))]

def build(size):
    global occ
    gmsh.initialize(); gmsh.option.setNumber("General.Terminal", 0)
    occ = gmsh.model.occ
    body = prism(wall, 0, top_z)
    walls = box(-B - wall, -B, -500, 500, -1, 100) + box(B, B + wall, -500, 500, -1, 100)
    cav, _ = occ.cut(prism(-wall, screen_gap, hood_in) + prism(-rim, -1, screen_gap), walls)
    zone, _ = occ.intersect(prism(-wall, hood_in - 0.01, top_z - skin_t), box(-B, B, -500, 500, -1, 100))
    body, _ = occ.cut(body, cav + zone)
    # panal interior: losa en la zona de pantalla menos celdas hexagonales
    slab, _ = occ.intersect(prism(-wall + 0.01, rib_bot, top_z - skin_t + 0.01), box(-B, B, -500, 500, -1, 100))
    p = core_s + core_rib; dx = p*math.sqrt(3)/2; R = core_s/math.sqrt(3)
    holes = []
    for i in range(-int(B/dx) - 2, int(B/dx) + 3):
        for j in range(-int(oy/p) - 2, int(oy/p) + 3):
            cx, cy = i*dx, j*p + (p/2 if i % 2 else 0)
            pts = [occ.addPoint(cx + R*math.cos(k*math.pi/3), cy + R*math.sin(k*math.pi/3), rib_bot - 1) for k in range(6)]
            f = occ.addPlaneSurface([occ.addCurveLoop([occ.addLine(pts[k], pts[(k+1) % 6]) for k in range(6)])])
            holes += [e for e in occ.extrude([(2, f)], 0, 0, rib_h + 3) if e[0] == 3]
    ribs, _ = occ.cut(slab, holes)
    occ.fuse(body, ribs)
    occ.synchronize()
    vol = sum(occ.getMass(*e) for e in gmsh.model.getEntities(3))
    gmsh.option.setNumber("Mesh.MeshSizeMax", size)
    gmsh.option.setNumber("Mesh.MeshSizeMin", size*0.3)
    gmsh.option.setNumber("Mesh.ElementOrder", 2)
    gmsh.option.setNumber("Mesh.SecondOrderLinear", 1)
    gmsh.option.setNumber("Mesh.Algorithm3D", 10)
    gmsh.option.setNumber("General.NumThreads", os.cpu_count())
    gmsh.model.mesh.generate(3)
    nt, X, _ = gmsh.model.mesh.getNodes()
    et, _, cn = gmsh.model.mesh.getElements(3)
    gmsh.finalize()
    pos = np.zeros(int(nt.max()) + 1, int); pos[nt.astype(int)] = np.arange(len(nt))
    conn = pos[cn[list(et).index(11)].astype(int).reshape(-1, 10)][:, [0, 1, 2, 3, 4, 5, 6, 7, 9, 8]]
    xyz = X.reshape(-1, 3)
    used = np.unique(conn); remap = np.zeros(len(xyz), int); remap[used] = np.arange(len(used))
    print(f"cuerpo CAD: {vol/1000:.1f} cm3, malla {len(used)} nodos, {len(conn)} tet10")
    return xyz[used], remap[conn]

if __name__ == "__main__":
    build(1.2)
