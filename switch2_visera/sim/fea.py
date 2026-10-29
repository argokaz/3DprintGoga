"""FEA de la visera: malla tetraédrica (gmsh) + CalculiX (ccx), elementos C3D10.

Uso: python3 sim/fea.py <caso> <material> [--size 1.0]
Casos: ver CASES abajo. Materiales: pla | petg.
Escribe resultados en sim/out/<caso>_<material>/ y un resumen JSON.
"""
import argparse, json, os, subprocess, sys
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)

# Propiedades de pieza impresa (conservadoras, 4 paredes, 0.2 mm).
# z del modelo = dirección de capas (se imprime boca abajo): S33 = tensión entre capas.
MATS = {
    "pla":  dict(E=3000., nu=0.35, s_xy=45., s_z=25., label="PLA"),
    "petg": dict(E=1900., nu=0.38, s_xy=40., s_z=28., label="PETG"),
}

# Geometría: se lee de switch2_visera.scad para no desincronizarse
import re
_SCAD = open(os.path.join(ROOT, "switch2_visera.scad")).read()
def P(name):
    return float(re.search(rf"^{name}\s*=\s*([-0-9.]+)\s*;", _SCAD, re.M).group(1))
L, H, T, tol, wall = P("console_L"), P("console_H"), P("console_T"), P("tol"), P("wall")
iL, iH = L + 2*tol, H + 2*tol
stick_h, stick_clear = P("stick_h"), P("stick_clear")
hood_in = stick_h + stick_clear
top_z = hood_in + P("hood_t")
rib_bot = top_z - P("skin_t") - P("rib_h")
clip_hook = P("clip_hook")
stick_L = (-L/2 + 17.75, H/2 - 35)     # estimación
stick_R = ( L/2 - 17.75, H/2 - 70)

def mesh_stl(stl, size, msh):
    """Malla tet10 con gmsh: reparametriza la superficie STL y malla el volumen.
    Nodos medios rectos (sin jacobianos negativos). Devuelve conn en orden C3D10."""
    import gmsh
    gmsh.initialize(); gmsh.option.setNumber("General.Terminal", 0)
    gmsh.merge(stl)
    gmsh.model.mesh.classifySurfaces(np.deg2rad(30), True, True, np.pi)
    gmsh.model.mesh.createGeometry()
    l = gmsh.model.geo.addSurfaceLoop([e[1] for e in gmsh.model.getEntities(2)])
    gmsh.model.geo.addVolume([l]); gmsh.model.geo.synchronize()
    gmsh.option.setNumber("Mesh.MeshSizeMax", size)
    gmsh.option.setNumber("Mesh.MeshSizeMin", size*0.4)
    gmsh.option.setNumber("Mesh.ElementOrder", 2)
    gmsh.option.setNumber("Mesh.SecondOrderLinear", 1)
    gmsh.option.setNumber("Mesh.Algorithm3D", 10)
    gmsh.option.setNumber("General.NumThreads", os.cpu_count())
    gmsh.model.mesh.generate(3)
    nt, X, _ = gmsh.model.mesh.getNodes()
    et, _, cn = gmsh.model.mesh.getElements(3)
    gmsh.finalize()
    pos = np.zeros(int(nt.max()) + 1, int); pos[nt.astype(int)] = np.arange(len(nt))
    conn = pos[cn[list(et).index(11)].astype(int).reshape(-1, 10)]
    conn = conn[:, [0, 1, 2, 3, 4, 5, 6, 7, 9, 8]]   # gmsh -> CalculiX (nodos 9/10)
    xyz = X.reshape(-1, 3)
    used = np.unique(conn); remap = np.zeros(len(xyz), int); remap[used] = np.arange(len(used))
    xyz, conn = xyz[used], remap[conn]
    print(f"malla: {len(xyz)} nodos, {len(conn)} tet10")
    return xyz, conn

def write_inp(path, xyz, conn, mat, bcs, loads, disp):
    with open(path, "w") as f:
        f.write("*NODE, NSET=NALL\n")
        for k, p in enumerate(xyz): f.write(f"{k+1},{p[0]:.5f},{p[1]:.5f},{p[2]:.5f}\n")
        f.write("*ELEMENT, TYPE=C3D10, ELSET=EALL\n")
        for k, c in enumerate(conn):
            c = c + 1
            f.write(f"{k+1}," + ",".join(map(str, c)) + "\n")
        f.write(f"*MATERIAL, NAME=M\n*ELASTIC\n{mat['E']},{mat['nu']}\n*SOLID SECTION, ELSET=EALL, MATERIAL=M\n")
        for name, (nodes, dofs) in bcs.items():
            f.write(f"*NSET, NSET={name}\n"); _ids(f, nodes)
        for name, (nodes, _) in disp.items():
            f.write(f"*NSET, NSET={name}\n"); _ids(f, nodes)
        f.write("*STEP\n*STATIC, SOLVER=ITERATIVE CHOLESKY\n" if len(xyz) > 700000 else "*STEP\n*STATIC\n")
        f.write("*BOUNDARY\n")
        for name, (nodes, dofs) in bcs.items():
            for d in dofs: f.write(f"{name},{d},{d},0\n")
        for name, (nodes, (d, val)) in disp.items():
            f.write(f"{name},{d},{d},{val}\n")
        if loads:
            f.write("*CLOAD\n")
            for n, d, v in loads: f.write(f"{n+1},{d},{v:.6f}\n")
        f.write("*NODE FILE\nU\n*EL FILE\nS\n*END STEP\n")

def _ids(f, nodes):
    ids = [str(n+1) for n in nodes]
    for i in range(0, len(ids), 12): f.write(",".join(ids[i:i+12]) + "\n")

def read_frd(path, nn):
    U = np.zeros((nn, 3)); S = np.zeros((nn, 6)); blk = None
    with open(path) as f:
        for line in f:
            if line.startswith("    1PSTEP") : continue
            if line.startswith(" -4"):
                blk = line.split()[1]; continue
            if line.startswith(" -1") and blk in ("DISP", "STRESS"):
                n = int(line[3:13]) - 1
                vals = [float(line[13+12*i:25+12*i]) for i in range((len(line.rstrip())-13)//12)]
                if blk == "DISP": U[n] = vals[:3]
                else: S[n] = vals[:6]
            if line.startswith(" -3"): blk = None
    return U, S

def vm(S):
    sx, sy, sz, txy, tyz, tzx = S.T
    return np.sqrt(0.5*((sx-sy)**2 + (sy-sz)**2 + (sz-sx)**2) + 3*(txy**2 + tyz**2 + tzx**2))

def inside_console(p, m=0.0):
    return (np.abs(p[:, 0]) < L/2 - m) & (np.abs(p[:, 1]) < H/2 - m)

def disc_load(xyz, cx, cy, r, ztop, F):
    sel = np.where((np.hypot(xyz[:, 0]-cx, xyz[:, 1]-cy) < r) & (np.abs(xyz[:, 2]-ztop) < 1e-3))[0]
    return [(n, 3, -F/len(sel)) for n in sel], sel

def supports_face(xyz):
    # la visera apoya en la cara frontal de la consola (z = 0)
    return np.where((np.abs(xyz[:, 2]) < 1e-3) & inside_console(xyz))[0]

def run(case, matname, size):
    mat = MATS[matname]
    c = CASES[case]
    out = os.path.join(HERE, "out", f"{case}_{matname}"); os.makedirs(out, exist_ok=True)
    msh_cache = os.path.join(HERE, "out", f"mesh_{os.path.basename(c['stl'])}_{size}.npz")
    if os.path.exists(msh_cache):
        d = np.load(msh_cache); xyz, conn = d["xyz"], d["conn"]
    elif c["stl"] == "occ":
        sys.path.insert(0, HERE); import body_occ
        xyz, conn = body_occ.build(size)
    else:
        xyz, conn = mesh_stl(os.path.join(ROOT, c["stl"]), size, None)
        np.savez(msh_cache, xyz=xyz, conn=conn)
    bcs, loads, disp, info = c["setup"](xyz)
    inp = os.path.join(out, "job.inp")
    write_inp(inp, xyz, conn, mat, bcs, loads, disp)
    for th in (os.cpu_count(), 1):   # spooles multihilo a veces muere con mallas grandes
        r = subprocess.run(["ccx", "-i", "job"], cwd=out, capture_output=True, text=True,
                           env=dict(os.environ, OMP_NUM_THREADS=str(th), CCX_NPROC_EQUATION_SOLVER=str(th)))
        if "Job finished" in r.stdout: break
        print(f"ccx con {th} hilos falló (código {r.returncode}): {r.stdout[-400:]}")
    else:
        sys.exit("ccx falló")
    U, S = read_frd(os.path.join(out, "job.frd"), len(xyz))
    v = vm(S); s33 = S[:, 2]
    # pico real, excluyendo solo los nodos a < 1.5 mm de cargas o apoyos impuestos
    # (ahí la tensión es una singularidad numérica, no física)
    from scipy.spatial import cKDTree
    pinned = set()
    for nodes, _ in list(bcs.values()) + list(disp.values()): pinned.update(int(n) for n in nodes)
    pinned.update(int(n) for n, _, _ in loads)
    far = np.ones(len(xyz), bool)
    if pinned:
        dist, _ = cKDTree(xyz[sorted(pinned)]).query(xyz)
        far = dist > 1.5
    def robust(a): return float(a[far].max())
    res = dict(case=case, material=mat["label"], nodes=len(xyz), elements=len(conn),
               umax_mm=float(np.abs(U).max()), uz_min_mm=float(U[:, 2].min()),
               vm_max_MPa=robust(v), s33_tension_max_MPa=robust(np.clip(s33, 0, None)),
               lim_xy=mat["s_xy"], lim_z=mat["s_z"], **info)
    res["SF_xy"] = mat["s_xy"] / res["vm_max_MPa"]
    res["SF_z"] = mat["s_z"] / max(res["s33_tension_max_MPa"], 1e-9)
    if "check" in c: res.update(c["check"](xyz, U, res))
    k = np.where(far)[0][np.argmax(np.clip(s33, 0, None)[far])]
    res["s33_peak_at"] = [round(float(c), 1) for c in xyz[k]]
    k = np.where(far)[0][np.argmax(v[far])]
    res["vm_peak_at"] = [round(float(c), 1) for c in xyz[k]]
    json.dump(res, open(os.path.join(out, "result.json"), "w"), indent=1)
    np.savez_compressed(os.path.join(out, "field.npz"), xyz=xyz, U=U, vm=v, s33=s33)
    print(json.dumps(res, indent=1))
    return res

# ------------------------------------------------------------------ casos
def setup_point(cx, cy, F, r=10):
    def f(xyz):
        sup = supports_face(xyz)
        loads, sel = disc_load(xyz, cx, cy, r, top_z, F)
        # anclaje en el plano: los nodos de apoyo no deslizan (rozamiento + dedos)
        return {"SUP": (sup, (1, 2, 3))}, loads, {}, dict(F_N=F, load_nodes=len(sel), sup_nodes=len(sup))
    return f

def setup_pressure(F_total):
    def f(xyz):
        sup = supports_face(xyz)
        top = np.where(np.abs(xyz[:, 2] - top_z) < 1e-3)[0]
        loads = [(n, 3, -F_total/len(top)) for n in top]
        return {"SUP": (sup, (1, 2, 3))}, loads, {}, dict(F_N=F_total, load_nodes=len(top))
    return f

def check_screen(xyz, U, res):
    # lo más bajo sobre la pantalla son los nervios (z = rib_bot): su bajada no debe llegar a la pantalla
    zone = (np.abs(xyz[:, 0]) < 87) & (np.abs(xyz[:, 1]) < 49) & (np.abs(xyz[:, 2] - rib_bot) < 1e-3)
    d = float(-U[zone, 2].min()) if zone.any() else 0.0
    return dict(screen_sag_mm=d, screen_gap_mm=rib_bot, touches_screen=bool(d >= rib_bot),
                screen_margin=rib_bot / max(d, 1e-9))

def check_stick(xyz, U, res):
    zone = (np.abs(xyz[:, 2] - hood_in) < 1e-3) & (np.hypot(xyz[:, 0]-stick_R[0], xyz[:, 1]-stick_R[1]) < 13)
    d = float(-U[zone, 2].min()) if zone.any() else 0.0
    return dict(hood_sag_over_stick_mm=d, stick_clearance_mm=stick_clear, touches_stick=bool(d >= stick_clear),
                stick_margin=stick_clear / max(d, 1e-9))

def setup_snap(delta):
    # probador de clips: tramo x 25..65; se empujan hacia fuera los ganchos de arriba y abajo
    def f(xyz):
        cut = np.where((np.abs(xyz[:, 0] - 25) < 1e-3) | (np.abs(xyz[:, 0] - 65) < 1e-3))[0]
        zb = -(T + tol)
        hook = lambda s: np.where((xyz[:, 2] < zb + 0.05) & (xyz[:, 2] > zb - 2) & (s*xyz[:, 1] > iH/2 - 1.2) & (s*xyz[:, 1] < iH/2 + 0.01))[0]
        up, dn = hook(1), hook(-1)
        return {"CUT": (cut, (1, 2, 3))}, [], {"HUP": (up, (2, delta)), "HDN": (dn, (2, -delta))}, dict(delta_mm=delta, hook_nodes=len(up) + len(dn))
    return f

CASES = {
    # rodilla / codo sobre el centro de la pantalla: 300 N ≈ 30 kg sobre Ø20 mm
    "screen_point":  dict(stl="occ", setup=setup_point(0, 0, 300), check=check_screen),
    # golpe/rodilla sobre la capucha del stick derecho
    "stick_point":   dict(stl="occ", setup=setup_point(*stick_R, 300), check=check_stick),
    # mochila aplastada: 500 N (≈ 50 kg) repartidos en toda la cara
    "backpack_crush": dict(stl="occ", setup=setup_pressure(500), check=check_screen),
    # poner/quitar la visera: el gancho se abre lo que sobresale (clip_hook – tol)
    "snap_fit":      dict(stl="stl/test_clip.stl", setup=setup_snap(clip_hook - tol)),
}

if __name__ == "__main__":
    ap = argparse.ArgumentParser(); ap.add_argument("case"); ap.add_argument("material")
    ap.add_argument("--size", type=float, default=1.0)
    a = ap.parse_args(); run(a.case, a.material, a.size)
