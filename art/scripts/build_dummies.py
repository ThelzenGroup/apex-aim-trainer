"""Build Apex-style target dummies from the CC0 Universal Animation Library mannequin.

For each size class in art/config/dummies.json this:
  1. scales the mannequin's height and girth (torso and limbs are thickened
     around their own bones, so every animation still fits the mesh),
  2. keeps the configured animation clips, deriving strafes from the forward
     cycles by turning the legs toward the strafe direction and twisting the
     spine back so the chest keeps facing forward,
  3. fits hitboxes to the mesh and parents them to bones so they follow every
     animation (the head hitbox drops when the dummy crouches),
  4. exports assets/models/dummy_<size>.glb plus a dummy_<size>.hitboxes.json
     sidecar for engines whose glTF importer drops node extras.

    pip install -r art/requirements.txt
    python art/scripts/fetch_sources.py
    python art/scripts/build_dummies.py [size ...]
"""
import json
import math
import struct
import sys
from pathlib import Path

import bpy  # must come first: the pip build of bpy provides bmesh and mathutils
import bmesh
from bpy_extras import anim_utils
from mathutils import Matrix, Quaternion, Vector

ROOT = Path(__file__).resolve().parents[2]
CONFIG = json.loads((ROOT / "art/config/dummies.json").read_text())
OUT = ROOT / "assets/models"

SPINE = ("spine_01", "spine_02", "spine_03")
REGION_COLORS = {
    "head": (0.95, 0.08, 0.08, 0.5),
    "body": (0.98, 0.82, 0.1, 0.35),
    "limb": (0.1, 0.55, 0.98, 0.35),
}
# Hitbox frame relative to its bone: X stays, Y = -bone Z, Z = bone Y (along the bone).
# The glTF exporter maps Blender Z-up to Y-up, so capsule axes come out along local +Y.
BONE_TO_HITBOX = Matrix(((1, 0, 0, 0), (0, 0, 1, 0), (0, -1, 0, 0), (0, 0, 0, 1)))


def channelbag(action):
    return anim_utils.action_get_channelbag_for_slot(action, action.slots[0])


def import_sources():
    """Fresh scene with the UAL1 mannequin and one action copy per configured clip."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.render.fps = CONFIG["fps"]
    source_actions = {}
    for key, rel in CONFIG["sources"].items():
        objects_before, actions_before = set(bpy.data.objects), set(bpy.data.actions)
        bpy.ops.import_scene.gltf(filepath=str(ROOT / rel))
        for action in set(bpy.data.actions) - actions_before:
            base = action.name.rsplit(".", 1)[0] if action.name[-4:-3] == "." else action.name
            source_actions[key, base] = action
        if key != "ual1":
            for obj in set(bpy.data.objects) - objects_before:
                bpy.data.objects.remove(obj)
    bpy.data.objects.remove(bpy.data.objects["Icosphere"])
    arm, mesh = bpy.data.objects["Armature"], bpy.data.objects["Mannequin"]

    clips = {}
    for clip, spec in CONFIG["animations"].items():
        action = source_actions[spec["source"], spec["action"]].copy()
        action.use_fake_user = True
        action.slots[0].name_display = arm.name
        clips[clip] = (action, spec)
    for action in source_actions.values():
        bpy.data.actions.remove(action)
    for clip, (action, _) in clips.items():
        action.name = clip
    return arm, mesh, clips


def scale_height(arm, mesh, clips, s):
    mesh.data.transform(Matrix.Scale(s, 4))
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="EDIT")
    for eb in arm.data.edit_bones:
        eb.head, eb.tail = eb.head * s, eb.tail * s
    bpy.ops.object.mode_set(mode="OBJECT")
    for action, _ in clips.values():
        for fc in channelbag(action).fcurves:
            if fc.data_path.endswith(".location"):
                for kp in fc.keyframe_points:
                    kp.co.y *= s
                    kp.handle_left.y *= s
                    kp.handle_right.y *= s
                fc.update()


def rotate_bone_keys(action, bone, q):
    """Pre-multiply every rotation key of `bone` by `q` (expressed in the bone's rest frame)."""
    cb = channelbag(action)
    path = f'pose.bones["{bone}"].rotation_quaternion'
    curves = [cb.fcurves.find(path, index=i) for i in range(4)]
    if all(c is None for c in curves):
        curves = [cb.fcurves.new(path, index=i) for i in range(4)]
        for c, value in zip(curves, (1, 0, 0, 0)):
            for frame in action.frame_range:
                c.keyframe_points.insert(frame, value)
    count = len(curves[0].keyframe_points)
    assert all(len(c.keyframe_points) == count for c in curves), f"{action.name}/{bone}: ragged keys"
    for k in range(count):
        new = q @ Quaternion([c.keyframe_points[k].co.y for c in curves])
        for c, value in zip(curves, new):
            kp = c.keyframe_points[k]
            kp.co.y = kp.handle_left.y = kp.handle_right.y = value
    for c in curves:
        c.update()


def make_strafe(action, yaw_degrees):
    yaw = math.radians(yaw_degrees)
    # root's rest frame is the armature frame, so local Z is world up.
    rotate_bone_keys(action, "root", Quaternion((0, 0, 1), yaw))
    # Spine bones point up, so their local Y is (nearly) world up.
    for bone in SPINE:
        rotate_bone_keys(action, bone, Quaternion((0, 1, 0), -yaw / len(SPINE)))


def thicken(arm, mesh, girth, head_girth):
    """Push each vertex away from its bones' axes, blended by skin weight."""
    axes = {b.name: (b.head_local.copy(), (b.tail_local - b.head_local).normalized()) for b in arm.data.bones}
    group_names = [g.name for g in mesh.vertex_groups]
    for v in mesh.data.vertices:
        offset, total = Vector(), 0.0
        for g in v.groups:
            name = group_names[g.group]
            head, axis = axes[name]
            d = v.co - head
            k = (head_girth if name == "Head" else girth) - 1.0
            offset += (d - axis * d.dot(axis)) * (k * g.weight)
            total += g.weight
        if total:
            v.co += offset / total


def hitbox_defs():
    defs = []
    for hb in CONFIG["hitboxes"]:
        defs.append(hb)
        if hb.get("mirror"):
            flip = lambda s: s[:-2] + "_r" if s.endswith("_l") else s
            defs.append({**hb, "name": flip(hb["name"]), "bones": [flip(b) for b in hb["bones"]]})
    return defs


def region_material(region):
    name = f"M_Hitbox_{region}"
    if name in bpy.data.materials:
        return bpy.data.materials[name]
    mat = bpy.data.materials.new(name)
    if mat.node_tree is None:
        mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    *rgb, alpha = REGION_COLORS[region]
    bsdf.inputs["Base Color"].default_value = (*rgb, 1)
    bsdf.inputs["Alpha"].default_value = alpha
    return mat


def add_capsule(bm, radius, height, segments=12, cap_rings=4):
    """Capsule along Z, built ring by ring so the vertex order is the same every build."""
    half = height / 2 - radius
    steps = [math.pi / 2 * i / cap_rings for i in range(1, cap_rings + 1)]
    profile = [(-half - radius * math.cos(t), radius * math.sin(t)) for t in steps]
    profile += [(half + radius * math.cos(t), radius * math.sin(t)) for t in reversed(steps)]
    angles = [2 * math.pi * s / segments for s in range(segments)]
    rings = [[bm.verts.new((r * math.cos(a), r * math.sin(a), z)) for a in angles] for z, r in profile]
    bottom, top = bm.verts.new((0, 0, -half - radius)), bm.verts.new((0, 0, half + radius))
    for s in range(segments):
        n = (s + 1) % segments
        bm.faces.new((bottom, rings[0][n], rings[0][s]))
        for lo, hi in zip(rings, rings[1:]):
            bm.faces.new((lo[s], lo[n], hi[n], hi[s]))
        bm.faces.new((top, rings[-1][s], rings[-1][n]))


def percentile(values, p):
    values = sorted(values)
    return values[round(p / 100 * (len(values) - 1))]


def add_hitboxes(arm, mesh):
    defs = hitbox_defs()
    owner = {bone: hb["name"] for hb in defs for bone in hb["bones"]}
    members = {hb["name"]: [] for hb in defs}
    group_names = [g.name for g in mesh.vertex_groups]
    for v in mesh.data.vertices:
        if not v.groups:
            continue
        bone = arm.data.bones[group_names[max(v.groups, key=lambda g: g.weight).group]]
        while bone and bone.name not in owner:
            bone = bone.parent
        if bone:
            members[owner[bone.name]].append(v.co.copy())

    for hb in defs:
        bone = arm.data.bones[hb["bones"][0]]
        frame = bone.matrix_local @ BONE_TO_HITBOX
        to_frame = frame.inverted()
        pts = [to_frame @ p for p in members[hb["name"]]]
        lo = Vector([min(p[i] for p in pts) for i in range(3)])
        hi = Vector([max(p[i] for p in pts) for i in range(3)])
        center = (lo + hi) / 2
        bm = bmesh.new()
        if hb["shape"] == "box":
            size = hi - lo
            bmesh.ops.create_cube(bm, size=1.0)
            for v in bm.verts:
                v.co = Vector([v.co[i] * size[i] for i in range(3)])
            dims = {"size": [size.x, size.z, size.y]}  # glTF axis order
        else:
            radius = percentile([math.hypot(p.x - center.x, p.y - center.y) for p in pts],
                                CONFIG["hitbox_radius_percentile"])
            height = max(hi.z - lo.z, 2 * radius)
            add_capsule(bm, radius, height)
            dims = {"radius": radius, "height": height}

        me = bpy.data.meshes.new(f"HB_{hb['region']}_{hb['name']}")
        bm.to_mesh(me)
        bm.free()
        me.materials.append(region_material(hb["region"]))
        obj = bpy.data.objects.new(me.name, me)
        bpy.context.scene.collection.objects.link(obj)
        obj.parent, obj.parent_type, obj.parent_bone = arm, "BONE", bone.name
        # Bone parenting attaches at the bone's tail; express the hitbox relative to that.
        tail = bone.matrix_local @ Matrix.Translation((0, bone.length, 0))
        obj.matrix_basis = tail.inverted() @ frame @ Matrix.Translation(center)
        obj["hitbox_region"] = hb["region"]
        obj["hitbox_shape"] = hb["shape"]
        for key, value in dims.items():
            obj[key] = [round(x, 4) for x in value] if isinstance(value, list) else round(value, 4)


def read_glb_json(path):
    data = path.read_bytes()
    (length,) = struct.unpack_from("<I", data, 12)
    return json.loads(data[20:20 + length])


def write_sidecar(glb, size_name, height_m):
    gltf = read_glb_json(glb)
    nodes = gltf["nodes"]
    parent = {child: i for i, n in enumerate(nodes) for child in n.get("children", [])}
    hitboxes = []
    for i, node in enumerate(nodes):
        if not node["name"].startswith("HB_"):
            continue
        extras = node["extras"]
        entry = {
            "name": node["name"],
            "region": extras["hitbox_region"],
            "bone": nodes[parent[i]]["name"],
            "shape": extras["hitbox_shape"],
            "translation": node.get("translation", [0, 0, 0]),
            "rotation": node.get("rotation", [0, 0, 0, 1]),
        }
        entry.update({k: extras[k] for k in ("radius", "height", "size") if k in extras})
        hitboxes.append(entry)
    sidecar = {
        "model": glb.name,
        "size_class": size_name,
        "height_m": round(height_m, 3),
        "notes": "Offsets are glTF node transforms relative to the bone's joint node. "
                 "Capsules run along local +Y; height includes both caps.",
        "animations": [a["name"] for a in gltf.get("animations", [])],
        "hitboxes": hitboxes,
    }
    glb.with_suffix(".hitboxes.json").write_text(json.dumps(sidecar, indent=2) + "\n")


def build(size_name, size):
    arm, mesh, clips = import_sources()
    scale_height(arm, mesh, clips, size["height"])
    for action, spec in clips.values():
        if "strafe_yaw" in spec:
            make_strafe(action, spec["strafe_yaw"])
    thicken(arm, mesh, size["girth"], size["head_girth"])
    add_hitboxes(arm, mesh)

    arm.animation_data.action = clips[CONFIG["default_animation"]][0]
    arm.animation_data.action_slot = arm.animation_data.action.slots[0]
    OUT.mkdir(parents=True, exist_ok=True)
    glb = OUT / f"dummy_{size_name}.glb"
    bpy.ops.export_scene.gltf(
        filepath=str(glb),
        export_format="GLB",
        export_extras=True,
        export_animations=True,
        export_animation_mode="ACTIONS",
        export_optimize_animation_size=True,
    )
    height = max(v.co.z for v in mesh.data.vertices)
    write_sidecar(glb, size_name, height)
    print(f"wrote {glb.relative_to(ROOT)} ({glb.stat().st_size / 1e6:.1f} MB, {height:.2f} m)")


if __name__ == "__main__":
    wanted = sys.argv[1:] or list(CONFIG["sizes"])
    for name in wanted:
        build(name, CONFIG["sizes"][name])
