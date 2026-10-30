"""Tramo de la visera como extrusión exacta (OpenCASCADE) de su corte transversal real.
Sirve para la solapa y el canal en zonas donde la pieza es un perfil constante en X."""
import os
import numpy as np
import gmsh, trimesh
from shapely.geometry import Polygon
from shapely.ops import unary_union

def build(stl, x0, x1, size, xsec=None):
    m = trimesh.load(stl)
    xs = xsec if xsec is not None else 0.5*(x0 + x1)
    sec = m.section(plane_origin=[xs, 0, 0], plane_normal=[1, 0, 0])
    shape = unary_union([Polygon(np.c_[e[:, 1], e[:, 2]]).buffer(0) for e in sec.discrete]).buffer(0)
    shape = shape.simplify(0.02)
    polys = list(shape.geoms) if hasattr(shape, "geoms") else [shape]
    gmsh.initialize(); gmsh.option.setNumber("General.Terminal", 0)
    occ = gmsh.model.occ
    def loop(coords):
        pts = [occ.addPoint(x0, y, z) for y, z in coords[:-1]]
        return occ.addCurveLoop([occ.addLine(pts[i], pts[(i+1) % len(pts)]) for i in range(len(pts))])
    vols = []
    for p in polys:
        if p.area < 0.05: continue
        loops = [loop(list(p.exterior.coords))] + [loop(list(h.coords)) for h in p.interiors]
        f = occ.addPlaneSurface(loops)
        vols += [e for e in occ.extrude([(2, f)], x1 - x0, 0, 0) if e[0] == 3]
    occ.synchronize()
    gmsh.option.setNumber("Mesh.MeshSizeMax", size)
    gmsh.option.setNumber("Mesh.MeshSizeMin", size*0.3)
    gmsh.option.setNumber("Mesh.ElementOrder", 2)
    gmsh.option.setNumber("Mesh.SecondOrderLinear", 1)
    gmsh.option.setNumber("Mesh.Algorithm3D", 10)
    gmsh.option.setNumber("Mesh.Optimize", 1)
    gmsh.option.setNumber("General.NumThreads", os.cpu_count())
    gmsh.model.mesh.generate(3)
    nt, X, _ = gmsh.model.mesh.getNodes()
    et, _, cn = gmsh.model.mesh.getElements(3)
    gmsh.finalize()
    pos = np.zeros(int(nt.max()) + 1, int); pos[nt.astype(int)] = np.arange(len(nt))
    conn = pos[cn[list(et).index(11)].astype(int).reshape(-1, 10)][:, [0, 1, 2, 3, 4, 5, 6, 7, 9, 8]]
    xyz = X.reshape(-1, 3)
    used = np.unique(conn); remap = np.zeros(len(xyz), int); remap[used] = np.arange(len(used))
    print(f"perfil extruido x {x0}..{x1}: {len(polys)} piezas, malla {len(used)} nodos, {len(conn)} tet10")
    return xyz[used], remap[conn]
