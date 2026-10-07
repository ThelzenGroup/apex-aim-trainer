"""Render preview sheets of the built dummies into art/previews/.

  lineup.jpg            every size class in rest pose with hitboxes overlaid
  anims_<size>.jpg      a contact sheet of every animation clip, hitboxes included

    python art/scripts/render_previews.py [size ...]   # animation sheets; default: medium
"""
import json
import sys
import tempfile
from pathlib import Path

import bpy
from mathutils import Vector
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
CONFIG = json.loads((ROOT / "art/config/dummies.json").read_text())
MODELS = ROOT / "assets/models"
PREVIEWS = ROOT / "art/previews"
FRAMES_PER_CLIP = 6
CELL = (180, 220)
BG = (24, 24, 28)


def new_scene(resolution, ortho_scale, camera_pos, target):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.fps = CONFIG["fps"]
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 24
    scene.render.resolution_x, scene.render.resolution_y = resolution
    scene.render.film_transparent = False

    scene.world = bpy.data.worlds.new("World")
    if scene.world.node_tree is None:
        scene.world.use_nodes = True
    scene.world.node_tree.nodes["Background"].inputs["Color"].default_value = (*(c / 255 for c in BG), 1)

    bpy.ops.mesh.primitive_plane_add(size=40)
    floor = bpy.data.materials.new("Floor")
    if floor.node_tree is None:
        floor.use_nodes = True
    floor.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.12, 0.12, 0.14, 1)
    bpy.context.active_object.data.materials.append(floor)

    bpy.ops.object.light_add(type="SUN", rotation=(0.9, 0.2, -0.6))
    bpy.context.active_object.data.energy = 3.5
    bpy.ops.object.light_add(type="SUN", rotation=(1.2, -0.3, 2.4))
    bpy.context.active_object.data.energy = 1.2

    bpy.ops.object.camera_add(location=camera_pos)
    cam = bpy.context.active_object
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = ortho_scale
    cam.rotation_euler = (Vector(target) - cam.location).to_track_quat("-Z", "Y").to_euler()
    scene.camera = cam
    return scene


def import_dummy(size):
    before_objects, before_actions = set(bpy.data.objects), set(bpy.data.actions)
    bpy.ops.import_scene.gltf(filepath=str(MODELS / f"dummy_{size}.glb"))
    arm = next(o for o in set(bpy.data.objects) - before_objects if o.type == "ARMATURE")
    actions = {a.name.rsplit(".", 1)[0] if a.name[-4:-3] == "." else a.name: a
               for a in set(bpy.data.actions) - before_actions}
    return arm, actions


def render_to(scene, path):
    scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)
    return Image.open(path).convert("RGB")


def lineup(sizes):
    spacing, width = 2.3, 2.3 * len(sizes)
    scene = new_scene((1200, 440), width, (0, -10.0, 1.9), (0, 0, 1.0))
    xs = [(i - (len(sizes) - 1) / 2) * spacing for i in range(len(sizes))]
    for size, x in zip(sizes, xs):
        arm, _ = import_dummy(size)
        arm.location.x = x
        arm.data.pose_position = "REST"
    with tempfile.TemporaryDirectory() as tmp:
        img = render_to(scene, Path(tmp) / "lineup.png")
    draw = ImageDraw.Draw(img)
    for size, x in zip(sizes, xs):
        draw.text((img.width * (0.5 + x / width) - 20, 12), size, fill=(230, 230, 230))
    img.save(PREVIEWS / "lineup.jpg", quality=88)
    print("wrote art/previews/lineup.jpg")


def anim_sheet(size):
    scene = new_scene(CELL, 2.6, (-4.0, -6.0, 2.2), (0, 0, 0.85))
    arm, actions = import_dummy(size)
    clips = list(CONFIG["animations"])
    sheet = Image.new("RGB", (CELL[0] * FRAMES_PER_CLIP, CELL[1] * len(clips)), BG)
    draw = ImageDraw.Draw(sheet)
    with tempfile.TemporaryDirectory() as tmp:
        for row, clip in enumerate(clips):
            action = actions[clip]
            arm.animation_data.action = action
            arm.animation_data.action_slot = action.slots[0]
            start, end = action.frame_range
            for col in range(FRAMES_PER_CLIP):
                scene.frame_set(round(start + (end - start) * col / FRAMES_PER_CLIP))
                cell = render_to(scene, Path(tmp) / f"{row}_{col}.png")
                sheet.paste(cell, (col * CELL[0], row * CELL[1]))
            draw.text((6, row * CELL[1] + 6), clip, fill=(240, 240, 240))
    out = PREVIEWS / f"anims_{size}.jpg"
    sheet.save(out, quality=88)
    print(f"wrote {out.relative_to(ROOT)}")


if __name__ == "__main__":
    PREVIEWS.mkdir(parents=True, exist_ok=True)
    lineup(list(CONFIG["sizes"]))
    for size in sys.argv[1:] or ["medium"]:
        anim_sheet(size)
