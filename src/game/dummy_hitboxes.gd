class_name DummyHitboxes
extends RefCounted
## Analytic hitboxes for one dummy instance.
##
## The glTF importer puts each HB_* node under a BoneAttachment3D with its shape data in
## the "extras" metadata. This reads them once and then tests rays with HitTest against the
## skeleton's current bone poses, so hit detection never waits for the physics step and box
## corners stay sharp.
##
## The importer's attachments are removed afterwards: Godot would otherwise move all 17 of
## them per bot every frame for nothing. The HB_* meshes are kept, hidden, as a debug view
## that sync_debug_meshes() places from the same math.


class Shape:
	extends RefCounted
	var name: String
	var region: String
	var bone: int
	var offset: Transform3D  ## Relative to the bone.
	var is_box: bool
	var radius: float
	var half_segment: float  ## Capsules: half the length of the segment between the cap centres.
	var half_extents: Vector3


## Limbs reach past their rest-pose distance from the pelvis in some animations.
const BOUND_MARGIN := 0.4

var skeleton: Skeleton3D
var shapes: Array[Shape] = []
var meshes: Array[MeshInstance3D] = []
var debug_visible := false
var bound_radius := 0.0
var _pelvis: int
# Pose snapshot used by intersect(); shape transforms are filled in lazily, only for
# bots that a ray actually comes near.
var _center: Vector3
var _world: Array[Transform3D] = []
var _world_valid := false


func _init(dummy_root: Node) -> void:
	skeleton = dummy_root.find_children("*", "Skeleton3D", true, false)[0]
	for attachment: BoneAttachment3D in skeleton.find_children("*", "BoneAttachment3D", false, false):
		for node in attachment.get_children():
			if node is MeshInstance3D and node.name.begins_with("HB_"):
				shapes.append(_shape_from(node, attachment.bone_idx))
				meshes.append(node)
				attachment.remove_child(node)
				dummy_root.add_child(node)
				node.top_level = true
		if attachment.get_child_count() == 0:
			attachment.free()
	set_debug_visible(false)

	_pelvis = skeleton.find_bone("pelvis")
	var pelvis_rest := skeleton.get_bone_global_rest(_pelvis).origin
	for s in shapes:
		var center := (skeleton.get_bone_global_rest(s.bone) * s.offset).origin
		var reach := s.half_extents.length() if s.is_box else s.half_segment + s.radius
		bound_radius = maxf(bound_radius, center.distance_to(pelvis_rest) + reach)
	bound_radius += BOUND_MARGIN
	_world.resize(shapes.size())
	update_pose()


static func _shape_from(node: MeshInstance3D, bone: int) -> Shape:
	var extras: Dictionary = node.get_meta("extras")
	var s := Shape.new()
	s.name = node.name
	s.region = extras["hitbox_region"]
	s.bone = bone
	s.offset = node.transform
	s.is_box = extras["hitbox_shape"] == "box"
	if s.is_box:
		var size: Array = extras["size"]
		s.half_extents = Vector3(size[0], size[1], size[2]) / 2.0
	else:
		s.radius = extras["radius"]
		s.half_segment = extras["height"] / 2.0 - s.radius
	return s


func set_debug_visible(visible: bool) -> void:
	debug_visible = visible
	for mesh in meshes:
		mesh.visible = visible
	if visible:
		sync_debug_meshes()


## Moves the debug meshes onto the current pose. The owner calls this each frame while
## debug_visible is on.
func sync_debug_meshes() -> void:
	for i in shapes.size():
		meshes[i].global_transform = shape_transform(shapes[i])


## World transform of a shape in the current pose.
func shape_transform(s: Shape) -> Transform3D:
	return skeleton.global_transform * skeleton.get_bone_global_pose(s.bone) * s.offset


## Snapshot the current pose. Call once per tick (or frame) before a batch of intersect() calls.
func update_pose() -> void:
	_center = skeleton.global_transform * skeleton.get_bone_global_pose(_pelvis).origin
	_world_valid = false


## Centre of the broad-phase sphere that contains every hitbox, as of update_pose().
func bound_center() -> Vector3:
	return _center


## Nearest hit on the segment from `from` along `dir` (normalized) up to `length` metres,
## against the pose captured by the last update_pose().
## Returns {"t": distance, "shape": Shape}, or an empty dictionary on a miss.
func intersect(from: Vector3, dir: Vector3, length: float) -> Dictionary:
	if HitTest.ray_sphere(from, dir, _center, bound_radius) > length:
		return {}
	if not _world_valid:
		var skeleton_xform := skeleton.global_transform
		for i in shapes.size():
			_world[i] = skeleton_xform * skeleton.get_bone_global_pose(shapes[i].bone) * shapes[i].offset
		_world_valid = true
	var best_t := INF
	var best: Shape = null
	for i in shapes.size():
		var s := shapes[i]
		var xform := _world[i]
		var t: float
		if s.is_box:
			t = HitTest.ray_box(from, dir, xform, s.half_extents)
		else:
			var axis := xform.basis.y * s.half_segment
			t = HitTest.ray_capsule(from, dir, xform.origin - axis, xform.origin + axis, s.radius)
		if t < best_t:
			best_t = t
			best = s
	if best == null or best_t > length:
		return {}
	return {"t": best_t, "shape": best}
