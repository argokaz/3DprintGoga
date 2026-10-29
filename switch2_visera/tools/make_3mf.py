#!/usr/bin/env python3
"""Build a Bambu Studio *project* .3mf (Bambu Lab A1, 0.4 mm nozzle) from an STL.

    python3 tools/make_3mf.py <in.stl> <out.3mf> --filament pla|petg

The archive mirrors what Bambu Studio's own writer (src/libslic3r/Format/bbs_3mf.cpp,
_BBS_3MF_Exporter) produces, so the loader treats it as a native project and
loads printer / filament / process presets instead of "geometry only":

  [Content_Types].xml
  _rels/.rels                          -> /3D/3dmodel.model (+ thumbnails)
  3D/3dmodel.model                     Application=BambuStudio-xx, object 2 = components
  3D/_rels/3dmodel.model.rels          -> /3D/Objects/object_1.model
  3D/Objects/object_1.model            object 1 = the mesh (production extension)
  Metadata/model_settings.config       object name + per-object overrides, part, plate 1
  Metadata/project_settings.config     flattened printer+process+filament presets (JSON)
  Metadata/slice_info.config           client header only (not sliced)
  Metadata/plate_1.png, plate_1_small.png, plate_no_light_1.png   thumbnails

Presets come from tools/bbl_a1_presets.json (resolved `inherits`/`include` chains of
the official BBL profiles).  Pass --profiles-dir <BambuStudio>/resources/profiles/BBL
to re-resolve them from a Bambu Studio checkout (this also rewrites the bundle).
"""

import argparse
import datetime as _dt
import io
import json
import os
import sys
import zipfile
from xml.sax.saxutils import escape, quoteattr

import numpy as np
import trimesh

HERE = os.path.dirname(os.path.abspath(__file__))
BUNDLE = os.path.join(HERE, "bbl_a1_presets.json")

# ---------------------------------------------------------------- presets ----
PRINTER = "Bambu Lab A1 0.4 nozzle"
PROCESS = "0.20mm Strength @BBL A1"
FILAMENTS = {
    "pla": ("Bambu PLA Basic @BBL A1", "#161616"),
    "petg": ("Bambu PETG HF @BBL A1", "#161616"),
}
BED_TYPE = "Textured PEI Plate"  # project option curr_bed_type (PresetBundle s_project_options)

# Process changes on top of "0.20mm Strength @BBL A1" (wall_loops 6, 25% grid,
# 5 top / 3 bottom, seam aligned, brim auto).  Written both into the project
# process preset (listed in different_settings_to_system so the loader keeps
# them) and as per-object overrides in model_settings.config.
PROCESS_OVERRIDES = {
    "layer_height": "0.2",
    "wall_loops": "4",
    "top_shell_layers": "5",
    "bottom_shell_layers": "4",
    "sparse_infill_density": "25%",
    "sparse_infill_pattern": "gyroid",
    "enable_support": "0",
    "brim_type": "no_brim",
    "seam_position": "back",
}
# Code defaults (PrintConfig.cpp) for override keys absent from the JSON chain.
CODE_DEFAULTS = {"brim_type": "auto_brim"}
OBJECT_OVERRIDE_KEYS = ["bottom_shell_layers", "brim_type", "enable_support", "seam_position",
                        "sparse_infill_density", "sparse_infill_pattern", "top_shell_layers",
                        "wall_loops"]

OBJECT_NAME = "Visera Switch 2"
BBS_VERSION = "02.00.00.00"   # >= 2.0.0: no legacy conversions in Plater::load_files;
                              # low enough not to trigger the "newer 3mf" dialog.

# keys of the profile JSON that are not config options of a full print config
META_KEYS = {"name", "inherits", "include", "from", "instantiation", "type", "setting_id",
             "filament_id", "description", "renamed_from", "alias", "compatible_printers",
             "compatible_printers_condition", "compatible_prints",
             "compatible_prints_condition", "is_custom_defined", "version", "url"}

# --------------------------------------------------------- preset resolving --


def _load_profile(root, kind, name):
    with open(os.path.join(root, kind, name + ".json"), encoding="utf-8") as f:
        return json.load(f)


def resolve_preset(root, kind, name):
    """Flatten like PresetBundle::load_vendor_configs_from_json: parent, includes, own."""
    d = _load_profile(root, kind, name)
    if "inherits" in d:
        cfg, meta = resolve_preset(root, kind, d["inherits"])
    else:
        cfg, meta = {}, {}
    for inc in d.get("include", []):
        inc_d = _load_profile(root, kind, inc)
        cfg.update({k: v for k, v in inc_d.items() if k not in META_KEYS})
    cfg.update({k: v for k, v in d.items() if k not in META_KEYS})
    meta = dict(meta)
    for k in ("filament_id", "compatible_printers"):
        if k in d:
            meta[k] = d[k]
    meta.update(name=d["name"], setting_id=d.get("setting_id", ""))
    return cfg, meta


def option_names(printconfig_cpp):
    """Option keys defined by PrintConfigDef (incl. the ones generated in loops)."""
    import re
    src = open(printconfig_cpp, encoding="utf-8").read()
    keys = set(re.findall(r'this->add(?:_nullable)?\("([^"]+)"', src))
    for vec in ("filament_extruder_override_keys", "filament_overhang_override_keys"):
        m = re.search(vec + r"\s*=\s*\{(.*?)\};", src, re.S)
        if m:
            keys |= set(re.findall(r'"([^"]+)"', m.group(1)))
    for kind in ("speed", "acceleration", "jerk"):
        keys |= {f"machine_max_{kind}_{a}" for a in "xyze"}
    return keys


def _describe_source(root):
    import subprocess
    try:
        rev = subprocess.run(["git", "-C", root, "log", "-1", "--format=%H %cs %s"], capture_output=True,
                             text=True, timeout=10).stdout.strip()
    except Exception:
        rev = ""
    return "BambuStudio resources/profiles/BBL" + (f" @ {rev}" if rev else "")


def build_bundle(root, printconfig_cpp=None):
    if printconfig_cpp is None:
        guess = os.path.join(root, "..", "..", "..", "src", "libslic3r", "PrintConfig.cpp")
        printconfig_cpp = guess if os.path.exists(guess) else None
    valid = option_names(printconfig_cpp) if printconfig_cpp else None
    dropped = set()

    def one(kind, name):
        cfg, meta = resolve_preset(root, kind, name)
        if valid is not None:
            # Preset::remove_invalid_keys / handle_legacy drop these on load anyway
            bad = [k for k in cfg if k not in valid]
            dropped.update(bad)
            for k in bad:
                del cfg[k]
        return {"meta": meta, "config": cfg}

    bundle = {
        "comment": "Resolved BBL system presets for make_3mf.py (inherits+include flattened)",
        "source": _describe_source(root),
        "printer": one("machine", PRINTER),
        "process": one("process", PROCESS),
        "filaments": {k: one("filament", v[0]) for k, v in FILAMENTS.items()},
    }
    bundle["dropped_keys_not_in_PrintConfigDef"] = sorted(dropped)
    return bundle


def load_bundle(profiles_dir):
    if profiles_dir:
        bundle = build_bundle(profiles_dir)
        with open(BUNDLE, "w", encoding="utf-8") as f:
            json.dump(bundle, f, indent=1, sort_keys=True, ensure_ascii=False)
            f.write("\n")
        return bundle
    if not os.path.exists(BUNDLE):
        sys.exit(f"missing {BUNDLE}; run once with --profiles-dir <BambuStudio>/resources/profiles/BBL")
    with open(BUNDLE, encoding="utf-8") as f:
        return json.load(f)


def project_settings(bundle, filament_key, colour):
    """Equivalent of PresetBundle::full_fff_config() saved with save_to_json()."""
    proc, prn = bundle["process"], bundle["printer"]
    fil = bundle["filaments"][filament_key]
    cfg = {}
    cfg.update(proc["config"])
    cfg.update(prn["config"])
    cfg.update(fil["config"])          # single filament: out.apply(filament_config)

    diff = []
    for k, v in sorted(PROCESS_OVERRIDES.items()):
        if proc["config"].get(k, CODE_DEFAULTS.get(k)) != v:
            diff.append(k)
        cfg[k] = v

    cfg.update({
        "name": "project_settings",
        "from": "project",
        "version": BBS_VERSION,
        "print_settings_id": proc["meta"]["name"],
        "printer_settings_id": prn["meta"]["name"],
        "filament_settings_id": [fil["meta"]["name"]],
        "filament_ids": [fil["meta"].get("filament_id", "")],
        "filament_colour": [colour],
        "filament_self_index": ["1"],
        "filament_map": ["1"],
        "curr_bed_type": BED_TYPE,
        "printer_technology": "FFF",
        "print_compatible_printers": proc["meta"].get("compatible_printers", []),
        # [print, filament 1..n, printer]; keys listed here keep the project value,
        # all others are reset to the system preset (update_non_diff_values_to_base_config)
        "different_settings_to_system": [";".join(diff), "", ""],
    })
    for k in ("inherits", "compatible_printers", "compatible_printers_condition",
              "compatible_prints", "compatible_prints_condition"):
        cfg.pop(k, None)
    return cfg, diff

# ------------------------------------------------------------------ mesh -----


def load_mesh(path):
    m = trimesh.load(path, force="mesh", process=True)
    if not isinstance(m, trimesh.Trimesh) or len(m.faces) == 0:
        sys.exit(f"{path}: no triangles")
    if m.volume < 0:
        m.invert()
    return m


def _g(x):
    return "%.9g" % x


def _fmt_vertices(v):
    return "".join('     <vertex x="%s" y="%s" z="%s"/>\n' % (_g(a), _g(b), _g(c)) for a, b, c in v)


def _fmt_triangles(f):
    return "".join('     <triangle v1="%d" v2="%d" v3="%d"/>\n' % (a, b, c) for a, b, c in f)


def _matrix3x4(t):
    # 3MF transform: columns of the 3x3 + translation, row-major per column (bbs add_transformation)
    m = np.asarray(t, dtype=float)
    return " ".join(_g(m[r, c]) for c in range(4) for r in range(3))


# ------------------------------------------------------------ thumbnails -----


def render_png(verts, faces, size, bg=(0, 0, 0, 0)):
    from PIL import Image, ImageDraw
    # camera: 35 deg elevation, looking from the front (-Y)
    el = np.radians(35.0)
    rx = np.array([[1, 0, 0], [0, np.cos(el), -np.sin(el)], [0, np.sin(el), np.cos(el)]])
    v = verts @ rx.T
    tri = v[faces]
    n = np.cross(tri[:, 1] - tri[:, 0], tri[:, 2] - tri[:, 0])
    n /= np.linalg.norm(n, axis=1, keepdims=True) + 1e-12
    xs, zs = v[:, 0], v[:, 2]
    span = max(np.ptp(xs), np.ptp(zs)) * 1.08
    cx, cz = (xs.max() + xs.min()) / 2, (zs.max() + zs.min()) / 2
    s = size / span
    px = (tri[:, :, 0] - cx) * s + size / 2
    py = size / 2 - (tri[:, :, 2] - cz) * s
    light = np.array([0.3, -0.6, 0.75]); light /= np.linalg.norm(light)
    shade = np.clip(np.abs(n @ light), 0, 1) * 0.75 + 0.25
    order = np.argsort(tri[:, :, 1].mean(axis=1))[::-1]  # far (large y) first
    img = Image.new("RGBA", (size, size), bg)
    dr = ImageDraw.Draw(img)
    base = np.array([0, 174, 66])  # Bambu green
    for i in order:
        c = tuple(int(x) for x in base * shade[i]) + (255,)
        dr.polygon([(px[i, 0], py[i, 0]), (px[i, 1], py[i, 1]), (px[i, 2], py[i, 2])], fill=c)
    buf = io.BytesIO()
    img.save(buf, "PNG")
    return buf.getvalue()

# --------------------------------------------------------------- writer ------


def bed_center(printer_cfg):
    pts = [tuple(float(c) for c in p.split("x")) for p in printer_cfg["printable_area"]]
    xs, ys = zip(*pts)
    return (min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2, (min(xs), max(xs), min(ys), max(ys))


def build_3mf(stl, out, filament_key, colour, bundle, thumbnails=True):
    mesh = load_mesh(stl)
    lo, hi = mesh.bounds
    center = (lo + hi) / 2.0
    verts = (mesh.vertices - center).astype(np.float32)   # volume-local, bbox-centred (as add_volume(center=true))
    faces = mesh.faces.astype(np.int64)
    size = hi - lo

    cx, cy, (bx0, bx1, by0, by1) = bed_center(bundle["printer"]["config"])
    tz = float(size[2]) / 2.0                     # z min -> 0
    item_tf = np.hstack([np.eye(3), np.array([[cx], [cy], [tz]])])

    # placement sanity
    wx0, wx1 = cx - size[0] / 2, cx + size[0] / 2
    wy0, wy1 = cy - size[1] / 2, cy + size[1] / 2
    if wx0 < bx0 or wx1 > bx1 or wy0 < by0 or wy1 > by1:
        print(f"WARNING: part {size[0]:.1f}x{size[1]:.1f} does not fit the bed", file=sys.stderr)
    if float(size[2]) > float(bundle["printer"]["config"].get("printable_height", "1e9")):
        print("WARNING: part taller than printable_height", file=sys.stderr)

    ps, diff = project_settings(bundle, filament_key, colour)
    app = "BambuStudio-" + BBS_VERSION
    today = _dt.date.today().isoformat()

    # ---- 3D/Objects/object_1.model (mesh) -- _add_mesh_to_object_stream
    hdr = ('<?xml version="1.0" encoding="UTF-8"?>\n'
           '<model unit="millimeter" xml:lang="en-US" '
           'xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02" '
           'xmlns:BambuStudio="http://schemas.bambulab.com/package/2021" '
           'xmlns:p="http://schemas.microsoft.com/3dmanufacturing/production/2015/06" '
           'requiredextensions="p">\n')
    obj_model = (hdr
                 + ' <metadata name="BambuStudio:3mfVersion">1</metadata>\n'
                 + ' <resources>\n'
                 + '  <object id="1" p:UUID="00010000-81cb-4c03-9d28-80fed5dfa1dc" type="model">\n'
                 + '   <mesh>\n    <vertices>\n' + _fmt_vertices(verts) + '    </vertices>\n'
                 + '    <triangles>\n' + _fmt_triangles(faces) + '    </triangles>\n'
                 + '   </mesh>\n  </object>\n </resources>\n <build/>\n</model>\n')

    # ---- 3D/3dmodel.model (root) -- _add_model_file_to_archive (split model)
    md = {
        "Application": app, "BambuStudio:3mfVersion": "1", "Copyright": "", "CreationDate": today,
        "Description": "", "Designer": "", "DesignerCover": "", "DesignerUserId": "",
        "License": "", "ModificationDate": today, "Origin": "", "ProfileCover": "",
        "ProfileDescription": "", "ProfileTitle": "", "Title": OBJECT_NAME,
    }
    root_model = hdr + "".join(f' <metadata name="{k}">{escape(v)}</metadata>\n' for k, v in sorted(md.items()))
    root_model += (' <resources>\n'
                   f'  <object id="2" p:UUID="00000001-61cb-4c03-9d28-80fed5dfa1dc" type="model" name={quoteattr(OBJECT_NAME)}>\n'
                   '   <components>\n'
                   '    <component p:path="/3D/Objects/object_1.model" objectid="1" '
                   'p:UUID="00010000-b206-40ff-9872-83e8017abed1" transform="1 0 0 0 1 0 0 0 1 0 0 0"/>\n'
                   '   </components>\n  </object>\n </resources>\n'
                   ' <build p:UUID="2c7c17d8-22b5-4d84-8835-1976022ea369">\n'
                   f'  <item objectid="2" p:UUID="00000002-b1ec-4553-aec9-835e5b724bb4" transform="{_matrix3x4(item_tf)}" printable="1"/>\n'
                   ' </build>\n</model>\n')

    model_rels = ('<?xml version="1.0" encoding="UTF-8"?>\n'
                  '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n'
                  ' <Relationship Target="/3D/Objects/object_1.model" Id="rel-1" '
                  'Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/>\n'
                  '</Relationships>')

    rels = ('<?xml version="1.0" encoding="UTF-8"?>\n'
            '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n'
            ' <Relationship Target="/3D/3dmodel.model" Id="rel-1" Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/>\n')
    if thumbnails:
        rels += (' <Relationship Target="/Metadata/plate_1.png" Id="rel-2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/thumbnail"/>\n'
                 ' <Relationship Target="/Metadata/plate_1.png" Id="rel-4" Type="http://schemas.bambulab.com/package/2021/cover-thumbnail-middle"/>\n'
                 ' <Relationship Target="/Metadata/plate_1_small.png" Id="rel-5" Type="http://schemas.bambulab.com/package/2021/cover-thumbnail-small"/>\n')
    rels += '</Relationships>'

    content_types = ('<?xml version="1.0" encoding="UTF-8"?>\n'
                     '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">\n'
                     ' <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>\n'
                     ' <Default Extension="model" ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml"/>\n'
                     ' <Default Extension="png" ContentType="image/png"/>\n'
                     ' <Default Extension="gcode" ContentType="text/x.gcode"/>\n'
                     '</Types>')

    # ---- Metadata/model_settings.config -- _add_model_config_file_to_archive
    obj_cfg = {"extruder": "1"}
    obj_cfg.update({k: PROCESS_OVERRIDES[k] for k in OBJECT_OVERRIDE_KEYS})
    ms = ['<?xml version="1.0" encoding="UTF-8"?>\n<config>\n',
          '  <object id="2">\n',
          f'    <metadata key="name" value={quoteattr(OBJECT_NAME)}/>\n']
    ms += [f'    <metadata key="{k}" value={quoteattr(v)}/>\n' for k, v in sorted(obj_cfg.items())]
    ms += [f'    <metadata face_count="{len(faces)}"/>\n',
           '    <part id="1" subtype="normal_part">\n',
           f'      <metadata key="name" value={quoteattr(OBJECT_NAME)}/>\n',
           '      <metadata key="matrix" value="1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1"/>\n',
           f'      <mesh_stat face_count="{len(faces)}" edges_fixed="0" degenerate_facets="0" '
           'facets_removed="0" facets_reversed="0" backwards_edges="0"/>\n',
           '    </part>\n  </object>\n',
           '  <plate>\n',
           '    <metadata key="plater_id" value="1"/>\n',
           '    <metadata key="plater_name" value=""/>\n',
           '    <metadata key="locked" value="false"/>\n']
    if thumbnails:
        ms += ['    <metadata key="thumbnail_file" value="Metadata/plate_1.png"/>\n',
               '    <metadata key="thumbnail_no_light_file" value="Metadata/plate_no_light_1.png"/>\n']
    ms += ['    <model_instance>\n',
           '      <metadata key="object_id" value="2"/>\n',
           '      <metadata key="instance_id" value="0"/>\n',
           '      <metadata key="identify_id" value="100"/>\n',
           '    </model_instance>\n  </plate>\n',
           '  <assemble>\n  </assemble>\n</config>\n']
    model_settings = "".join(ms)

    slice_info = ('<?xml version="1.0" encoding="UTF-8"?>\n<config>\n  <header>\n'
                  '    <header_item key="X-BBL-Client-Type" value="slicer"/>\n'
                  f'    <header_item key="X-BBL-Client-Version" value="{BBS_VERSION}"/>\n'
                  '  </header>\n</config>\n')

    files = [
        ("[Content_Types].xml", content_types),
        ("_rels/.rels", rels),
        ("3D/3dmodel.model", root_model),
        ("3D/_rels/3dmodel.model.rels", model_rels),
        ("3D/Objects/object_1.model", obj_model),
        ("Metadata/model_settings.config", model_settings),
        ("Metadata/project_settings.config", json.dumps(ps, indent=4, sort_keys=True, ensure_ascii=False) + "\n"),
        ("Metadata/slice_info.config", slice_info),
    ]
    if thumbnails:
        world = verts.astype(np.float64)
        big = render_png(world, faces, 512)
        files += [("Metadata/plate_1.png", big), ("Metadata/plate_no_light_1.png", big),
                  ("Metadata/plate_1_small.png", render_png(world, faces, 128))]

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        for name, data in files:
            z.writestr(name, data.encode("utf-8") if isinstance(data, str) else data)

    print(f"{out}: {len(mesh.vertices)} vertices, {len(faces)} triangles, "
          f"size {size[0]:.2f} x {size[1]:.2f} x {size[2]:.2f} mm, placed at ({cx:g}, {cy:g}, z0=0)")
    print(f"  printer  : {ps['printer_settings_id']}  bed: {BED_TYPE}")
    print(f"  process  : {ps['print_settings_id']}  modified: {', '.join(diff)}")
    print(f"  filament : {ps['filament_settings_id'][0]} ({ps['filament_ids'][0]})")
    return out


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("stl")
    ap.add_argument("out")
    ap.add_argument("--filament", choices=sorted(FILAMENTS), required=True)
    ap.add_argument("--colour", help="filament colour #RRGGBB (only for AMS mapping / preview)")
    ap.add_argument("--profiles-dir", help="<BambuStudio>/resources/profiles/BBL; re-resolves and rewrites the preset bundle")
    ap.add_argument("--no-thumbnail", action="store_true")
    a = ap.parse_args(argv)
    bundle = load_bundle(a.profiles_dir)
    colour = a.colour or FILAMENTS[a.filament][1]
    build_3mf(a.stl, a.out, a.filament, colour, bundle, thumbnails=not a.no_thumbnail)


if __name__ == "__main__":
    main()
