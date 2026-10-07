"""Sanity-check the exported dummies straight from the .glb files (stdlib only, no Blender).

Reads each glTF node hierarchy the way an engine would, so it catches export
mistakes the Blender round trip would hide.

    python art/scripts/check_dummies.py
"""
import json
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CONFIG = json.loads((ROOT / "art/config/dummies.json").read_text())
TOL = 1e-3


def load_glb(path):
    data = path.read_bytes()
    (json_len,) = struct.unpack_from("<I", data, 12)
    return json.loads(data[20:20 + json_len])


def trs(node):
    x, y, z, w = node.get("rotation", [0, 0, 0, 1])
    sx, sy, sz = node.get("scale", [1, 1, 1])
    tx, ty, tz = node.get("translation", [0, 0, 0])
    return [
        [(1 - 2 * (y * y + z * z)) * sx, 2 * (x * y - z * w) * sy, 2 * (x * z + y * w) * sz, tx],
        [2 * (x * y + z * w) * sx, (1 - 2 * (x * x + z * z)) * sy, 2 * (y * z - x * w) * sz, ty],
        [2 * (x * z - y * w) * sx, 2 * (y * z + x * w) * sy, (1 - 2 * (x * x + y * y)) * sz, tz],
        [0, 0, 0, 1],
    ]


def matmul(a, b):
    return [[sum(a[i][k] * b[k][j] for k in range(4)) for j in range(4)] for i in range(4)]


def world_matrices(gltf):
    nodes, world = gltf["nodes"], {}

    def walk(i, parent):
        world[i] = matmul(parent, trs(nodes[i]))
        for c in nodes[i].get("children", []):
            walk(c, world[i])

    identity = [[float(i == j) for j in range(4)] for i in range(4)]
    for root in gltf["scenes"][gltf.get("scene", 0)]["nodes"]:
        walk(root, identity)
    return world


def check(size):
    path = ROOT / f"assets/models/dummy_{size}.glb"
    gltf = load_glb(path)
    sidecar = json.loads(path.with_suffix(".hitboxes.json").read_text())
    nodes, accessors, errors = gltf["nodes"], gltf["accessors"], []

    clips = {a["name"] for a in gltf.get("animations", [])}
    missing = set(CONFIG["animations"]) - clips
    if missing:
        errors.append(f"missing animations {sorted(missing)}")

    expected = sum(2 if hb.get("mirror") else 1 for hb in CONFIG["hitboxes"])
    hb_nodes = {n["name"]: i for i, n in enumerate(nodes) if n["name"].startswith("HB_")}
    if len(hb_nodes) != expected or len(sidecar["hitboxes"]) != expected:
        errors.append(f"expected {expected} hitboxes, glb has {len(hb_nodes)}, sidecar {len(sidecar['hitboxes'])}")

    world = world_matrices(gltf)
    centers = {name: [world[i][r][3] for r in range(3)] for name, i in hb_nodes.items()}
    for name, i in hb_nodes.items():
        extras = nodes[i]["extras"]
        acc = accessors[gltf["meshes"][nodes[i]["mesh"]]["primitives"][0]["attributes"]["POSITION"]]
        extent = [hi - lo for lo, hi in zip(acc["min"], acc["max"])]
        if extras["hitbox_shape"] == "box":
            want = extras["size"]
        else:
            want = [2 * extras["radius"], extras["height"], 2 * extras["radius"]]
        if any(abs(a - b) > TOL for a, b in zip(extent, want)):
            errors.append(f"{name}: mesh extent {extent} != declared {want}")

    head = centers["HB_head_head"]
    if head[1] != max(c[1] for c in centers.values()):
        errors.append("head hitbox is not the highest hitbox in rest pose")
    if abs(head[1] - (sidecar["height_m"] - 0.12)) > 0.08:
        errors.append(f"head hitbox at y={head[1]:.2f} m, model is {sidecar['height_m']} m tall")
    for name, (x, y, z) in centers.items():
        if name.endswith("_l"):
            rx, ry, rz = centers[name[:-2] + "_r"]
            if abs(x + rx) > TOL or abs(y - ry) > TOL or abs(z - rz) > TOL:
                errors.append(f"{name} is not mirrored by its _r twin")

    print(f"{size:7s} {'OK' if not errors else 'FAIL'}  {len(clips)} clips, {len(hb_nodes)} hitboxes, "
          f"head at {head[1]:.2f} m of {sidecar['height_m']} m")
    for e in errors:
        print("   ", e)
    return not errors


if __name__ == "__main__":
    sys.exit(0 if all([check(size) for size in CONFIG["sizes"]]) else 1)
